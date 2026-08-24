import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_data/ez_data.dart';
import '../../security/state/security_provider.dart';
import 'package:ez_domain/ez_domain.dart';
import '../../sync/state/sync_mutation_observer_provider.dart';
import '../../../app/local_storage_scope_provider.dart';
import '../../../shared/state/notification_providers.dart';

final plainMemoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return ref.watch(localStorageScopeProvider).memoryRepository;
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final plainRepository = ref.watch(plainMemoryRepositoryProvider);
  final backend = ref.watch(localStorageScopeProvider).secureEntityBackend;
  final cipher = session.cipher;
  if (session.hasPin && cipher != null) {
    return EncryptedMemoryRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: plainRepository,
      backend: backend,
    );
  }
  return plainRepository;
});

final memoryItemsControllerProvider =
    StateNotifierProvider<MemoryItemsController, List<MemoryItem>>((ref) {
  return MemoryItemsController(
    ref.watch(memoryRepositoryProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(mediaStorageProvider),
    ref.watch(syncMutationObserverProvider),
  );
});

final mediaStorageProvider = Provider<MediaStorage>((ref) => MediaStorage());

final memoryItemsLoadProvider = FutureProvider<void>((ref) {
  return ref.watch(memoryItemsControllerProvider.notifier).load();
});

class MemoryItemsController extends StateNotifier<List<MemoryItem>> {
  MemoryItemsController(
    this._repository, [
    this._reminders,
    this._mediaStorage,
    this._sync,
  ]) : super(const []) {
    _loadFuture = _load();
  }

  final MemoryRepository _repository;
  final ReminderScheduler? _reminders;
  final MediaStorage? _mediaStorage;
  final SyncMutationObserver? _sync;
  late final Future<void> _loadFuture;
  final _writes = SequentialTaskQueue();

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    final items = await _repository.loadAll();
    state = _sort(items);
    unawaited(_safeReconcile());
  }

  /// Записи, лежащие в хранилище прямо сейчас.
  ///
  /// Вхождение повтора обычно проецируется и строки не имеет, поэтому тем,
  /// кто сохраняет правку, нужно уметь отличить одно от другого.
  List<MemoryItem> get items => state;

  Future<void> add(MemoryItem item) async {
    await _loadFuture;
    state = _sort([...state, item]);
    await _writes.add(() => _repository.upsert(item));
    _sync?.memoryChanged();
    if (_hasFutureReminder(item)) unawaited(_safeSchedule(item));
  }

  Future<void> addAll(List<MemoryItem> items) async {
    if (items.isEmpty) return;
    await _loadFuture;
    final itemsById = {
      for (final item in state) item.id: item,
      for (final item in items) item.id: item,
    };
    state = _sort(itemsById.values.toList());
    await _writes.add(() => _repository.upsertAll(items));
    _sync?.memoryChanged();
    unawaited(_safeScheduleAll(items));
  }

  Future<void> update(MemoryItem item) async {
    await _loadFuture;
    final previous = _findById(item.id);
    state = _sort([
      for (final existing in state)
        if (existing.id == item.id) item else existing,
    ]);
    await _writes.add(() => _repository.upsert(item));
    _sync?.memoryChanged();
    if (previous != null) {
      await _cleanupRemovedMedia(previous, item);
    }
    if (_hasFutureReminder(item)) {
      unawaited(_safeSchedule(item));
    } else if (previous?.remindAt != null) {
      unawaited(_safeCancel(item.id));
    }
  }

  Future<void> archive(String id) async {
    await _loadFuture;
    final now = DateTime.now();
    state = _sort([
      for (final item in state)
        if (item.id == id)
          item.copyWith(status: MemoryStatus.archived, updatedAt: now)
        else
          item,
    ]);
    final archived = _findById(id);
    if (archived != null) {
      await _writes.add(() => _repository.upsert(archived));
      _sync?.memoryChanged();
    }
    unawaited(_safeCancel(id));
  }

  Future<void> restore(String id) async {
    await _loadFuture;
    final now = DateTime.now();
    state = _sort([
      for (final item in state)
        if (item.id == id)
          item.copyWith(status: MemoryStatus.active, updatedAt: now)
        else
          item,
    ]);
    final restored = _findById(id);
    if (restored != null) {
      await _writes.add(() => _repository.upsert(restored));
      _sync?.memoryChanged();
      if (_hasFutureReminder(restored)) unawaited(_safeSchedule(restored));
    }
  }

  Future<void> toggleDone(String id) async {
    await _loadFuture;
    final now = DateTime.now();
    state = _sort([
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            status: item.isDone ? MemoryStatus.active : MemoryStatus.done,
            updatedAt: now,
          )
        else
          item,
    ]);
    final updated = _findById(id);
    if (updated != null) {
      await _writes.add(() => _repository.upsert(updated));
      _sync?.memoryChanged();
    }
    if (updated == null || updated.status != MemoryStatus.active) {
      unawaited(_safeCancel(id));
    } else {
      unawaited(_safeSchedule(updated));
    }
  }

  Future<void> delete(String id) async {
    await _loadFuture;
    final deletedAt = DateTime.now();
    final removed = _findById(id);
    // Persist the cloud deletion before removing the local row. If the app is
    // interrupted between these writes, the next sync can still finish the
    // deletion instead of downloading the stale cloud copy again.
    await _sync?.memoryDeleted(id, deletedAt);
    state = [
      for (final item in state)
        if (item.id != id) item,
    ];
    await _writes.add(() => _repository.delete(id));
    if (removed != null) {
      await _deleteUnusedMedia(_mediaPaths(removed));
    }
    unawaited(_safeCancel(id));
  }

  /// Removes a row whose content another representation has taken over.
  /// Unlike [delete] this keeps the media and the reminder: the record still
  /// exists, only where it is stored has changed. Deleting the media here
  /// would strip photos that the new owner still points at.
  Future<void> retireRow(String id) async {
    await _loadFuture;
    if (!state.any((item) => item.id == id)) return;
    await _sync?.memoryDeleted(id, DateTime.now());
    state = [
      for (final item in state)
        if (item.id != id) item,
    ];
    await _writes.add(() => _repository.delete(id));
  }

  Future<List<MemoryItem>> duplicateToDates(
    MemoryItem source,
    Iterable<DateTime> dates,
  ) async {
    await _loadFuture;
    final created = <MemoryItem>[];
    final now = DateTime.now();
    var index = 0;
    for (final rawDate in dates) {
      final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
      if (_sameDay(date, source.memoryDate)) continue;
      final reminder = _movedReminder(source, date, now);
      final copy = source.copyWith(
        id: '${now.microsecondsSinceEpoch}_${index++}',
        memoryDate: date,
        createdAt: now,
        updatedAt: now,
        status: MemoryStatus.active,
        remindAt: reminder,
        clearReminder: reminder == null,
        clearSeries: true,
        clearRepeatRule: true,
        isGeneratedOccurrence: false,
      );
      await add(copy);
      created.add(copy);
    }
    return created;
  }

  Future<void> replaceAll(List<MemoryItem> items) async {
    await _loadFuture;
    await _persistReplacement(await _withoutDeletedItems(items));
  }

  Future<void> replaceAllFromSync(
    List<MemoryItem> items, {
    required List<MemoryItem> baseline,
  }) async {
    await _loadFuture;
    final mergedById = {
      for (final item in await _withoutDeletedItems(items)) item.id: item,
    };
    final currentById = {for (final item in state) item.id: item};
    final baselineById = {for (final item in baseline) item.id: item};

    // A missing current row that existed in the snapshot was deleted while
    // the network request was in flight. Never re-add it from that snapshot.
    for (final id in baselineById.keys) {
      if (!currentById.containsKey(id)) mergedById.remove(id);
    }
    for (final current in currentById.values) {
      final before = baselineById[current.id];
      final changedDuringSync =
          before == null || current.updatedAt.isAfter(before.updatedAt);
      if (!changedDuringSync) continue;
      final incoming = mergedById[current.id];
      if (incoming == null ||
          !incoming.updatedAt.isAfter(current.updatedAt)) {
        mergedById[current.id] = current;
      }
    }
    await _persistReplacement(mergedById.values.toList(growable: false));
  }

  Future<List<MemoryItem>> _withoutDeletedItems(
    Iterable<MemoryItem> items,
  ) async {
    final accepted = <MemoryItem>[];
    for (final item in items) {
      final deletedAt = await _sync?.memoryDeletedAt(item.id);
      if (deletedAt == null || item.updatedAt.isAfter(deletedAt)) {
        accepted.add(item);
      }
    }
    return accepted;
  }

  Future<void> _persistReplacement(List<MemoryItem> items) async {
    state = _sort(items);
    await _writes.add(() => _repository.replaceAll(state));
    unawaited(_safeReconcile());
  }

  /// Removes legacy generated rows after their user edits have been migrated
  /// to recurrence exceptions. Media stays intact because an exception may be
  /// its only remaining owner, while sync still receives deletion tombstones.
  Future<void> removeMigratedRecurrenceCopies(Iterable<String> ids) async {
    await _loadFuture;
    final requested = ids.toSet();
    final removedIds = {
      for (final item in state)
        if (requested.contains(item.id)) item.id,
    };
    if (removedIds.isEmpty) return;
    final deletedAt = DateTime.now();
    for (final id in removedIds) {
      await _sync?.memoryDeleted(id, deletedAt);
    }
    state = _sort([
      for (final item in state)
        if (!removedIds.contains(item.id)) item,
    ]);
    await _writes.add(() => _repository.replaceAll(state));
    for (final id in removedIds) {
      unawaited(_safeCancel(id));
    }
    unawaited(_safeReconcile());
  }

  Future<void> _safeSchedule(MemoryItem item) async {
    try {
      await _reminders?.schedule(item);
    } catch (_) {
      // Saving the record must not fail if Android rejects a notification.
    }
  }

  Future<void> _safeScheduleAll(Iterable<MemoryItem> items) async {
    var scheduled = 0;
    for (final item in items.where(_hasFutureReminder)) {
      await _safeSchedule(item);
      if (++scheduled % 8 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  Future<void> _safeCancel(String id) async {
    try {
      await _reminders?.cancel(id);
    } catch (_) {
      // Local data remains authoritative when notification cleanup fails.
    }
  }

  Future<void> _safeReconcile() async {
    try {
      await _reminders?.reconcile(state);
    } catch (_) {
      // A later app launch or edit will retry notification reconciliation.
    }
  }

  Future<void> _cleanupRemovedMedia(
    MemoryItem previous,
    MemoryItem current,
  ) async {
    final removed = _mediaPaths(previous)..removeAll(_mediaPaths(current));
    await _deleteUnusedMedia(removed);
  }

  Future<void> _deleteUnusedMedia(Iterable<String> paths) async {
    try {
      await _mediaStorage?.deleteOwnedFiles(
        paths,
        usedPaths: {for (final item in state) ..._mediaPaths(item)},
      );
    } catch (_) {
      // A later maintenance pass can retry orphan cleanup.
    }
  }

  Set<String> _mediaPaths(MemoryItem item) => {
        ...item.imagePaths,
        if (item.audioPath != null) item.audioPath!,
      };

  MemoryItem? _findById(String id) {
    for (final item in state) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  List<MemoryItem> _sort(List<MemoryItem> items) {
    return [...items]..sort((a, b) {
        final byDate = a.memoryDate.compareTo(b.memoryDate);
        if (byDate != 0) {
          return byDate;
        }
        return b.priority.compareTo(a.priority);
      });
  }

  DateTime? _movedReminder(
    MemoryItem source,
    DateTime targetDate,
    DateTime now,
  ) {
    final reminder = source.remindAt;
    if (reminder == null) return null;
    final sourceDate = DateTime(
      source.memoryDate.year,
      source.memoryDate.month,
      source.memoryDate.day,
    );
    final dayOffset = reminder.difference(sourceDate);
    final moved = targetDate.add(dayOffset);
    return moved.isAfter(now) ? moved : null;
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _hasFutureReminder(MemoryItem item) =>
    item.status == MemoryStatus.active &&
    item.remindAt?.isAfter(DateTime.now()) == true;
