import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/data/encrypted_json_store.dart';
import '../../security/state/security_provider.dart';
import '../../notifications/data/notification_service.dart';
import '../data/encrypted_memory_repository.dart';
import '../data/memory_repository.dart';
import '../data/memory_repository_factory.dart';
import '../domain/memory_item.dart';
import '../domain/memory_status.dart';

final plainMemoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final repository = createMemoryRepository();
  ref.onDispose(() => unawaited(repository.close()));
  return repository;
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final plainRepository = ref.watch(plainMemoryRepositoryProvider);
  final cipher = session.cipher;
  if (session.hasPin && cipher != null) {
    return EncryptedMemoryRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: plainRepository,
    );
  }
  return plainRepository;
});

final memoryItemsControllerProvider =
    StateNotifierProvider<MemoryItemsController, List<MemoryItem>>((ref) {
  return MemoryItemsController(
    ref.watch(memoryRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
});

class MemoryItemsController extends StateNotifier<List<MemoryItem>> {
  MemoryItemsController(this._repository, [this._reminders]) : super(const []) {
    _loadFuture = _load();
  }

  final MemoryRepository _repository;
  final ReminderScheduler? _reminders;
  late final Future<void> _loadFuture;
  Future<void> _writeTail = Future.value();

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    final items = await _repository.loadAll();
    state = _sort(items);
    unawaited(_safeReconcile());
  }

  Future<void> add(MemoryItem item) async {
    await _loadFuture;
    state = _sort([...state, item]);
    await _enqueueWrite(() => _repository.upsert(item));
    unawaited(_safeSchedule(item));
  }

  Future<void> update(MemoryItem item) async {
    await _loadFuture;
    state = _sort([
      for (final existing in state)
        if (existing.id == item.id) item else existing,
    ]);
    await _enqueueWrite(() => _repository.upsert(item));
    unawaited(_safeSchedule(item));
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
      await _enqueueWrite(() => _repository.upsert(archived));
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
      await _enqueueWrite(() => _repository.upsert(restored));
      unawaited(_safeSchedule(restored));
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
      await _enqueueWrite(() => _repository.upsert(updated));
    }
    if (updated == null || updated.status != MemoryStatus.active) {
      unawaited(_safeCancel(id));
    } else {
      unawaited(_safeSchedule(updated));
    }
  }

  Future<void> delete(String id) async {
    await _loadFuture;
    state = [
      for (final item in state)
        if (item.id != id) item,
    ];
    await _enqueueWrite(() => _repository.delete(id));
    unawaited(_safeCancel(id));
  }

  Future<void> replaceAll(List<MemoryItem> items) async {
    await _loadFuture;
    state = _sort(items);
    await _enqueueWrite(() => _repository.replaceAll(state));
    unawaited(_safeReconcile());
  }

  Future<void> _safeSchedule(MemoryItem item) async {
    try {
      await _reminders?.schedule(item);
    } catch (_) {
      // Saving the record must not fail if Android rejects a notification.
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

  Future<void> _enqueueWrite(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return next;
  }

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
}
