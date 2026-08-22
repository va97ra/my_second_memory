import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_status.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../notifications/data/notification_service.dart';
import '../../sync/domain/sync_mutation_observer.dart';
import '../data/recurrence_repository.dart';
import '../domain/recurrence_occurrence_exception.dart';
import '../domain/recurrence_projection_service.dart';
import '../domain/recurrence_series.dart';
import 'recurrence_exception_controller.dart';

class RecurrenceSeriesController extends StateNotifier<List<RecurrenceSeries>> {
  RecurrenceSeriesController(
      this._repository, this._exceptions, this._memoryItems, this._reminders,
      [this._sync])
      : super(const []) {
    _loadFuture = _load();
  }

  final RecurrenceRepository _repository;
  final RecurrenceExceptionController _exceptions;
  final MemoryItemsController _memoryItems;
  final ReminderScheduler _reminders;
  final SyncMutationObserver? _sync;
  late final Future<void> _loadFuture;

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    await Future.wait([_memoryItems.load(), _exceptions.load()]);
    state = await _repository.loadAll();
    await _migrateGeneratedCopies();
    await _applyMemoryDeletionTombstones();
    await _restoreOriginOverrides();
    await _applySkippedOccurrenceDeletes();
    await _refreshStaleTemplatesFromOrigins();
    await _materializeHistory(DateTime.now());
    unawaited(_reconcileRecurringReminders());
  }

  Future<RecurrenceSeries> setFrequency(
    MemoryItem item,
    RecurrenceFrequency frequency,
  ) async {
    await _loadFuture;
    final now = DateTime.now();
    final id = item.seriesId ?? 'recurrence_${item.id}';
    final linked = item.copyWith(
      seriesId: id,
      repeatRule: frequency.name,
      isGeneratedOccurrence: false,
      updatedAt: now,
    );
    if (_memoryItems.state.any((item) => item.id == linked.id)) {
      await _memoryItems.update(linked);
    } else {
      await _memoryItems.add(linked);
    }
    final existing = _find(id);
    final series = RecurrenceSeries(
      id: id,
      frequency: frequency,
      template: linked,
      startDate: existing?.startDate ?? linked.memoryDate,
      originItemId: existing?.originItemId ?? linked.id,
      isEnabled: true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      endDate: existing?.endDate,
      subscriptionEndDate: frequency == RecurrenceFrequency.monthly &&
              linked.type == MemoryType.payment &&
              linked.paymentCategory == PaymentCategory.subscription.name
          ? existing?.subscriptionEndDate
          : null,
      historyThrough: dateOnly(now),
    );
    await _repository.upsert(series);
    state = _replace(series);
    _sync?.recurrenceSeriesChanged();
    unawaited(_reconcileRecurringReminders());
    return series;
  }

  Future<void> clearFrequency(MemoryItem item) async {
    await _loadFuture;
    final seriesId = item.seriesId;
    if (seriesId == null) return;
    final now = DateTime.now();
    // Make the cloud deletion durable before removing the local series. If
    // the process is interrupted during the local cleanup, the next sync must
    // finish the deletion instead of downloading the live cloud row again.
    await _sync?.recurrenceSeriesDeleted(seriesId, now);
    for (final occurrence in [..._memoryItems.state]) {
      if (occurrence.seriesId != seriesId) continue;
      await _memoryItems.update(
        occurrence.copyWith(
          clearSeries: true,
          clearRepeatRule: true,
          isGeneratedOccurrence: false,
          updatedAt: now,
        ),
      );
    }
    await _exceptions.deleteSeries(seriesId);
    await _repository.delete(seriesId);
    state = [
      for (final series in state)
        if (series.id != seriesId) series
    ];
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await _loadFuture;
    final current = _find(id);
    if (current == null) return;
    final updated = current.copyWith(
      isEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
    state = _replace(updated);
    _sync?.recurrenceSeriesChanged();
    unawaited(_reconcileRecurringReminders());
  }

  Future<RecurrenceSeries?> setTermMonths(String id, int? months) async {
    await _loadFuture;
    if (months != null && months <= 0) {
      throw ArgumentError.value(months, 'months', 'Must be greater than zero');
    }
    final current = _find(id);
    if (current == null) return null;
    final subscriptionEndDate = months == null
        ? null
        : safeDate(
            current.startDate.year,
            current.startDate.month + months - 1,
            current.startDate.day,
          );
    if ((current.subscriptionEndDate == null && subscriptionEndDate == null) ||
        (current.subscriptionEndDate != null &&
            subscriptionEndDate != null &&
            dateKey(current.subscriptionEndDate!) ==
                dateKey(subscriptionEndDate))) {
      return current;
    }
    final updated = current.copyWith(
      subscriptionEndDate: subscriptionEndDate,
      clearSubscriptionEndDate: subscriptionEndDate == null,
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
    state = _replace(updated);
    _sync?.recurrenceSeriesChanged();
    unawaited(_reconcileRecurringReminders());
    return updated;
  }

  Future<RecurrenceSeries?> applyToFuture(
    MemoryItem edited, {
    DateTime? occurrenceDate,
  }) async {
    await _loadFuture;
    final currentId = edited.seriesId;
    if (currentId == null) return null;
    final current = _find(currentId);
    if (current == null) return null;
    final now = DateTime.now();
    final cutoff = _sourceDateForItem(edited, occurrenceDate);
    final replacementStart = dateOnly(edited.memoryDate);
    final ended = current.copyWith(
      endDate: cutoff.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
    final newId =
        '${current.id}_${dateKey(cutoff)}_${now.microsecondsSinceEpoch}';
    final linked = edited.copyWith(
      seriesId: newId,
      repeatRule: current.frequency.name,
      isGeneratedOccurrence: false,
      updatedAt: now,
    );
    final replacement = RecurrenceSeries(
      id: newId,
      frequency: current.frequency,
      template: linked,
      startDate: replacementStart,
      originItemId: linked.id,
      createdAt: now,
      updatedAt: now,
      endDate: current.endDate,
      subscriptionEndDate: current.frequency == RecurrenceFrequency.monthly &&
              linked.type == MemoryType.payment &&
              linked.paymentCategory == PaymentCategory.subscription.name
          ? current.subscriptionEndDate
          : null,
      historyThrough: dateOnly(now),
    );
    await _repository.upsertAll([ended, replacement]);
    state = [..._replace(ended), replacement];
    _sync?.recurrenceSeriesChanged();
    if (_memoryItems.state.any((item) => item.id == linked.id)) {
      await _memoryItems.update(linked);
    } else {
      await _memoryItems.add(linked);
    }
    await _exceptions.delete(currentId, cutoff);
    unawaited(_reconcileRecurringReminders());
    return replacement;
  }

  Future<void> saveOccurrenceOverride(
    MemoryItem item, {
    DateTime? occurrenceDate,
  }) async {
    await _loadFuture;
    final seriesId = item.seriesId;
    if (seriesId == null) return;
    final sourceDate = _sourceDateForItem(item, occurrenceDate);
    final series = _find(seriesId);
    if (series?.originItemId == item.id) {
      final now = DateTime.now();
      final exceptionId = recurrenceExceptionId(seriesId, sourceDate);
      RecurrenceOccurrenceException? existing;
      for (final exception in _exceptions.state) {
        if (exception.id == exceptionId) {
          existing = exception;
          break;
        }
      }
      final normalized = item.copyWith(
        seriesId: seriesId,
        repeatRule: series!.frequency.name,
        isGeneratedOccurrence: false,
        updatedAt: now,
      );
      await _deleteMiskeyedOverrides(normalized, sourceDate);
      // The exception is also an explicit marker that this origin was edited
      // as a single occurrence. Persist it before the origin so a restart can
      // never mistake that edit for a stale series template.
      await _exceptions.upsert(
        RecurrenceOccurrenceException(
          id: exceptionId,
          seriesId: seriesId,
          occurrenceDate: sourceDate,
          kind: RecurrenceOccurrenceExceptionKind.modified,
          item: normalized,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      if (_memoryItems.state.any((entry) => entry.id == normalized.id)) {
        await _memoryItems.update(normalized);
      } else {
        await _memoryItems.add(normalized);
      }
      unawaited(_reconcileRecurringReminders());
      return;
    }
    final normalized = item.copyWith(
      id: occurrenceId(seriesId, sourceDate),
      isGeneratedOccurrence: true,
      updatedAt: DateTime.now(),
    );
    final isPastOrToday =
        !dateOnly(item.memoryDate).isAfter(dateOnly(DateTime.now()));
    final exceptionId = recurrenceExceptionId(seriesId, sourceDate);
    RecurrenceOccurrenceException? existing;
    for (final exception in _exceptions.state) {
      if (exception.id == exceptionId) {
        existing = exception;
        break;
      }
    }
    final survivesMemoryDeletion =
        !isPastOrToday && existing?.survivesMemoryDeletion == true;
    if (isPastOrToday) {
      if (_memoryItems.state.any((entry) => entry.id == normalized.id)) {
        await _memoryItems.update(normalized);
      } else {
        await _memoryItems.add(normalized);
      }
      if (dateKey(sourceDate) == dateKey(item.memoryDate)) {
        await _exceptions.delete(seriesId, sourceDate);
      } else {
        final now = DateTime.now();
        await _exceptions.upsert(
          RecurrenceOccurrenceException(
            id: exceptionId,
            seriesId: seriesId,
            occurrenceDate: sourceDate,
            kind: RecurrenceOccurrenceExceptionKind.modified,
            item: normalized,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
      }
    } else {
      final now = DateTime.now();
      await _exceptions.upsert(
        RecurrenceOccurrenceException(
          id: exceptionId,
          seriesId: seriesId,
          occurrenceDate: sourceDate,
          kind: RecurrenceOccurrenceExceptionKind.modified,
          item: normalized,
          survivesMemoryDeletion: survivesMemoryDeletion,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> toggleOccurrenceDone(MemoryItem item) async {
    await saveOccurrenceOverride(
      item.copyWith(
        status: item.isDone ? MemoryStatus.active : MemoryStatus.done,
      ),
    );
  }

  Future<void> archiveOccurrence(MemoryItem item) =>
      saveOccurrenceOverride(item.copyWith(status: MemoryStatus.archived));

  Future<void> restoreOccurrence(MemoryItem item) =>
      saveOccurrenceOverride(item.copyWith(status: MemoryStatus.active));

  Future<void> deleteOccurrence(MemoryItem item) async {
    await _loadFuture;
    final seriesId = item.seriesId;
    if (seriesId == null) {
      await _memoryItems.delete(item.id);
      return;
    }
    final sourceDate = _sourceDateForItem(item);
    await _deleteMiskeyedOverrides(item, sourceDate);
    await _writeDeletionMarker(item, sourceDate);
    await _memoryItems.delete(item.id);
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> deleteSeries(String id) async {
    await _loadFuture;
    final deletedAt = DateTime.now();
    // Persist the series tombstone first. Future occurrences are virtual, so
    // deleting only materialized memory rows cannot prevent a stale cloud
    // series from projecting them again after a crash.
    await _sync?.recurrenceSeriesDeleted(id, deletedAt);
    for (final item in [..._memoryItems.state]) {
      if (item.seriesId == id) await _memoryItems.delete(item.id);
    }
    await _exceptions.deleteSeries(id);
    await _repository.delete(id);
    state = [
      for (final series in state)
        if (series.id != id) series
    ];
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> deleteFromDate(
    String id,
    DateTime from, {
    MemoryItem? occurrence,
  }) async {
    await _loadFuture;
    final current = _find(id);
    if (current == null) return;
    // A moved occurrence keeps its original date encoded in its id/exception.
    // Series boundaries must use that source date, not the visible destination.
    final cutoff = occurrence == null
        ? dateOnly(from)
        : _sourceDateForItem(occurrence, from);
    final updated = current.copyWith(
      endDate: cutoff.subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
    state = _replace(updated);
    _sync?.recurrenceSeriesChanged();
    for (final item in [..._memoryItems.state]) {
      if (item.seriesId == id &&
          !_sourceDateForItem(item, item.memoryDate).isBefore(cutoff)) {
        await _memoryItems.delete(item.id);
      }
    }
    for (final exception in [..._exceptions.state]) {
      if (exception.seriesId != id) continue;
      final sourceDate = exception.item == null
          ? dateOnly(exception.occurrenceDate)
          : _sourceDateForItem(exception.item!, exception.occurrenceDate);
      if (!sourceDate.isBefore(cutoff)) {
        await _exceptions.delete(id, exception.occurrenceDate);
      }
    }
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> replaceAll(List<RecurrenceSeries> series) async {
    await _loadFuture;
    await _replaceAllAndReconcile(series);
  }

  Future<void> replaceAllFromSync(
    List<RecurrenceSeries> series, {
    required List<RecurrenceSeries> baseline,
  }) async {
    await _loadFuture;
    final mergedById = {for (final item in series) item.id: item};
    final currentById = {for (final item in state) item.id: item};
    final baselineById = {for (final item in baseline) item.id: item};
    for (final id in baselineById.keys) {
      if (!currentById.containsKey(id)) mergedById.remove(id);
    }
    for (final current in currentById.values) {
      final before = baselineById[current.id];
      final changedDuringSync =
          before == null || current.updatedAt.isAfter(before.updatedAt);
      if (!changedDuringSync) continue;
      final incoming = mergedById[current.id];
      if (incoming == null || !incoming.updatedAt.isAfter(current.updatedAt)) {
        mergedById[current.id] = current;
      }
    }
    await _replaceAllAndReconcile(
      mergedById.values.toList(growable: false),
    );
  }

  Future<void> _replaceAllAndReconcile(List<RecurrenceSeries> series) async {
    await _repository.replaceAll(series);
    state = series;
    await _migrateGeneratedCopies();
    await _applyMemoryDeletionTombstones();
    await _restoreOriginOverrides();
    await _applySkippedOccurrenceDeletes();
    await _refreshStaleTemplatesFromOrigins();
    await _materializeHistory(DateTime.now());
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> ensureOccurrences() async {
    await _loadFuture;
    await _materializeHistory(DateTime.now());
    await _reconcileRecurringReminders();
  }

  Future<void> ensureHorizonFor(DateTime visibleMonth) async {
    await _loadFuture;
    // Calendar occurrences are projected on demand; no database work is needed.
  }

  Future<void> _refreshStaleTemplatesFromOrigins() async {
    if (state.isEmpty || _memoryItems.state.isEmpty) return;
    final itemsById = {
      for (final item in _memoryItems.state) item.id: item,
    };
    final repaired = <RecurrenceSeries>[];
    var latestTimestamp = DateTime.now();
    for (final series in state) {
      final origin = itemsById[series.originItemId];
      final template = series.template;
      final hasOriginOverride = _exceptions.state.any(
        (exception) =>
            exception.seriesId == series.id &&
            (dateKey(exception.occurrenceDate) == dateKey(series.startDate) ||
                exception.item?.id == series.originItemId),
      );
      if (origin == null ||
          hasOriginOverride ||
          origin.seriesId != series.id ||
          origin.id != template.id ||
          origin.isGeneratedOccurrence ||
          !origin.updatedAt.isAfter(template.updatedAt) ||
          !_looksLikeIncompleteInitialSave(series, origin)) {
        continue;
      }
      if (!latestTimestamp.isAfter(series.updatedAt)) {
        latestTimestamp = series.updatedAt.add(const Duration(microseconds: 1));
      }
      if (!latestTimestamp.isAfter(origin.updatedAt)) {
        latestTimestamp = origin.updatedAt.add(const Duration(microseconds: 1));
      }
      repaired.add(
        series.copyWith(
          template: origin.copyWith(
            seriesId: series.id,
            repeatRule: series.frequency.name,
            isGeneratedOccurrence: false,
          ),
          updatedAt: latestTimestamp,
        ),
      );
      latestTimestamp = latestTimestamp.add(const Duration(microseconds: 1));
    }
    if (repaired.isEmpty) return;
    await _repository.upsertAll(repaired);
    final replacements = {for (final series in repaired) series.id: series};
    state = [
      for (final series in state) replacements[series.id] ?? series,
    ];
    _sync?.recurrenceSeriesChanged();
  }

  bool _looksLikeIncompleteInitialSave(
    RecurrenceSeries series,
    MemoryItem origin,
  ) {
    final editDelay = origin.updatedAt.difference(series.createdAt);
    final template = series.template;
    if (template.updatedAt != series.createdAt ||
        origin.type != template.type ||
        origin.createdAt != template.createdAt ||
        dateKey(origin.memoryDate) != dateKey(template.memoryDate) ||
        dateKey(template.memoryDate) != dateKey(series.startDate) ||
        editDelay.isNegative ||
        editDelay > const Duration(minutes: 2)) {
      return false;
    }
    // The legacy autosave bug captured either a partially typed line or the
    // item before its type-specific metadata was filled. Restrict the repair
    // to those completion patterns so an arbitrary occurrence override is not
    // promoted to the whole series.
    final expandedText = _expandedDuringInitialSave(
          template.title,
          origin.title,
        ) ||
        _expandedDuringInitialSave(template.body, origin.body);
    final filledMissingMetadata = (template.amountMinor == null &&
            origin.amountMinor != null) ||
        (template.paymentCategory == null && origin.paymentCategory != null) ||
        (template.birthYear == null && origin.birthYear != null);
    return expandedText || filledMissingMetadata;
  }

  bool _expandedDuringInitialSave(String before, String after) {
    final partial = before.trim();
    final completed = after.trim();
    if (partial.isEmpty || partial == completed || completed.isEmpty) {
      return false;
    }
    // The affected legacy save captured the tail of a name (for example,
    // "Анаста" before a surname was prepended). A normal append such as
    // "Купить" -> "Купить молоко" must remain scoped to one occurrence.
    final wordCharacter = RegExp(r'[A-Za-zА-Яа-яЁё0-9]');
    var start = completed.indexOf(partial);
    while (start > 0) {
      final end = start + partial.length;
      final hasLeftBoundary =
          !wordCharacter.hasMatch(completed.substring(start - 1, start));
      final continuesWord = end < completed.length &&
          wordCharacter.hasMatch(completed.substring(end, end + 1));
      if (hasLeftBoundary && continuesWord) return true;
      start = completed.indexOf(partial, start + 1);
    }
    return false;
  }

  Future<void> _restoreOriginOverrides() async {
    if (state.isEmpty || _exceptions.state.isEmpty) return;
    final memoryDeletions =
        await _sync?.memoryDeletions() ?? const <String, DateTime>{};
    final itemsById = {
      for (final item in _memoryItems.state) item.id: item,
    };
    for (final series in state) {
      final canonicalId = recurrenceExceptionId(series.id, series.startDate);
      final related = [
        for (final exception in _exceptions.state)
          if (exception.seriesId == series.id &&
              (exception.id == canonicalId ||
                  exception.item?.id == series.originItemId))
            exception,
      ];
      if (related.isEmpty) continue;
      var winner = related.first;
      for (final exception in related.skip(1)) {
        if (exception.updatedAt.isAfter(winner.updatedAt)) {
          winner = exception;
        }
      }
      if (winner.isSkipped || winner.item == null) {
        for (final exception in related) {
          if (exception.id != canonicalId) {
            await _exceptions.delete(series.id, exception.occurrenceDate);
          }
        }
        continue;
      }
      final item = winner.item!;
      if (item.id != series.originItemId || item.isGeneratedOccurrence) {
        continue;
      }
      // A recurrence marker can recover a partially written edit. A newer
      // marker is also allowed to recreate an intentionally re-added item,
      // while an equal/newer deletion remains authoritative.
      final deletedAt = memoryDeletions[item.id];
      if (deletedAt != null &&
          !winner.updatedAt.isAfter(deletedAt) &&
          !item.updatedAt.isAfter(deletedAt)) {
        continue;
      }
      if (winner.id != canonicalId) {
        RecurrenceOccurrenceException? existingCanonical;
        for (final exception in related) {
          if (exception.id == canonicalId) {
            existingCanonical = exception;
            break;
          }
        }
        winner = RecurrenceOccurrenceException(
          id: canonicalId,
          seriesId: series.id,
          occurrenceDate: dateOnly(series.startDate),
          kind: RecurrenceOccurrenceExceptionKind.modified,
          item: item,
          createdAt: existingCanonical?.createdAt ?? winner.createdAt,
          updatedAt: winner.updatedAt,
        );
        // Write the canonical copy first. A retry may briefly see two markers,
        // but an interruption can never discard the newest user edit.
        await _exceptions.upsert(winner);
      }
      await _deleteMiskeyedOverrides(item, dateOnly(series.startDate));
      final persisted = itemsById[series.originItemId];
      if (persisted != null && !item.updatedAt.isAfter(persisted.updatedAt)) {
        continue;
      }
      final restored = item.copyWith(
        seriesId: series.id,
        repeatRule: series.frequency.name,
        isGeneratedOccurrence: false,
        updatedAt: winner.updatedAt.isAfter(item.updatedAt)
            ? winner.updatedAt
            : item.updatedAt,
      );
      if (persisted == null) {
        await _memoryItems.add(restored);
      } else {
        await _memoryItems.update(restored);
      }
      itemsById[item.id] = restored;
    }
  }

  DateTime _sourceDateForItem(MemoryItem item, [DateTime? fallback]) {
    final seriesId = item.seriesId;
    if (seriesId == null) return dateOnly(fallback ?? item.memoryDate);
    final series = _find(seriesId);
    if (series?.originItemId == item.id) {
      return dateOnly(series!.startDate);
    }
    final encoded = occurrenceDateFromId(seriesId, item.id);
    if (encoded != null) return dateOnly(encoded);
    RecurrenceOccurrenceException? newest;
    for (final exception in _exceptions.state) {
      if (exception.seriesId != seriesId || exception.item?.id != item.id) {
        continue;
      }
      if (newest == null || exception.updatedAt.isAfter(newest.updatedAt)) {
        newest = exception;
      }
    }
    return dateOnly(newest?.occurrenceDate ?? fallback ?? item.memoryDate);
  }

  Future<void> _deleteMiskeyedOverrides(
    MemoryItem item,
    DateTime sourceDate,
  ) async {
    final seriesId = item.seriesId;
    if (seriesId == null) return;
    for (final exception in [..._exceptions.state]) {
      if (exception.seriesId != seriesId ||
          dateKey(exception.occurrenceDate) == dateKey(sourceDate)) {
        continue;
      }
      // A null-item skip at the moved date can be a deliberate deletion of a
      // real occurrence. Only markers carrying this exact item id are safe to
      // canonicalize automatically.
      if (exception.item?.id == item.id) {
        await _exceptions.delete(seriesId, exception.occurrenceDate);
      }
    }
  }

  Future<void> reconcileOriginOverrides() async {
    await _loadFuture;
    await _applyMemoryDeletionTombstones();
    await _restoreOriginOverrides();
    await _applySkippedOccurrenceDeletes();
  }

  Future<void> _applyMemoryDeletionTombstones() async {
    if (_sync == null) return;
    final memoryDeletions = await _sync.memoryDeletions();
    for (final series in state) {
      final deletedAt = memoryDeletions[series.originItemId];
      if (deletedAt == null) continue;
      final id = recurrenceExceptionId(series.id, series.startDate);
      RecurrenceOccurrenceException? existing;
      for (final exception in _exceptions.state) {
        if (exception.id == id) {
          existing = exception;
          break;
        }
      }
      final markerIsNewer = existing != null &&
          (existing.updatedAt.isAfter(deletedAt) ||
              existing.item?.updatedAt.isAfter(deletedAt) == true);
      if (markerIsNewer) {
        continue;
      }
      if (existing?.isSkipped == true &&
          existing?.item?.id == series.originItemId &&
          !deletedAt.isAfter(existing!.updatedAt)) {
        continue;
      }
      final origin = series.template.copyWith(
        id: series.originItemId,
        seriesId: series.id,
        repeatRule: series.frequency.name,
        isGeneratedOccurrence: false,
      );
      await _writeDeletionMarker(
        origin,
        dateOnly(series.startDate),
        deletedAt: deletedAt,
      );
      await _deleteMiskeyedOverrides(origin, dateOnly(series.startDate));
    }
    if (_exceptions.state.isEmpty) return;
    for (final exception in [..._exceptions.state]) {
      final item = exception.item;
      if (item == null) continue;
      final deletedAt = memoryDeletions[item.id];
      if (deletedAt == null) continue;
      if (!exception.isSkipped && exception.survivesMemoryDeletion) continue;
      if (!exception.isSkipped &&
          (exception.updatedAt.isAfter(deletedAt) ||
              item.updatedAt.isAfter(deletedAt))) {
        continue;
      }
      final sourceDate = _sourceDateForItem(item, exception.occurrenceDate);
      final canonicalId = recurrenceExceptionId(exception.seriesId, sourceDate);
      if (exception.id == canonicalId &&
          exception.isSkipped &&
          exception.item?.id == item.id &&
          !deletedAt.isAfter(exception.updatedAt)) {
        continue;
      }
      await _writeDeletionMarker(item, sourceDate, deletedAt: deletedAt);
      await _deleteMiskeyedOverrides(item, sourceDate);
    }
  }

  Future<void> _writeDeletionMarker(
    MemoryItem item,
    DateTime sourceDate, {
    DateTime? deletedAt,
  }) async {
    final seriesId = item.seriesId;
    if (seriesId == null) return;
    final timestamp = deletedAt ?? DateTime.now();
    final id = recurrenceExceptionId(seriesId, sourceDate);
    RecurrenceOccurrenceException? existing;
    for (final exception in _exceptions.state) {
      if (exception.id == id) {
        existing = exception;
        break;
      }
    }
    await _exceptions.upsert(
      RecurrenceOccurrenceException(
        id: id,
        seriesId: seriesId,
        occurrenceDate: dateOnly(sourceDate),
        kind: RecurrenceOccurrenceExceptionKind.skipped,
        item: item,
        createdAt: existing?.createdAt ?? timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  Future<void> _applySkippedOccurrenceDeletes() async {
    if (_exceptions.state.isEmpty || _memoryItems.state.isEmpty) return;
    final memoryDeletions =
        await _sync?.memoryDeletions() ?? const <String, DateTime>{};
    for (final exception in [..._exceptions.state]) {
      if (!exception.isSkipped) continue;
      for (final item in [..._memoryItems.state]) {
        if (item.seriesId != exception.seriesId ||
            dateKey(_sourceDateForItem(item)) !=
                dateKey(exception.occurrenceDate)) {
          continue;
        }
        final deletedAt = memoryDeletions[item.id];
        final deletionWins =
            deletedAt != null && !item.updatedAt.isAfter(deletedAt);
        final explicitlyDeleted = exception.item?.id == item.id;
        final isUnmoved =
            dateKey(item.memoryDate) == dateKey(exception.occurrenceDate);
        if (!explicitlyDeleted && !isUnmoved && !deletionWins) continue;
        if (!deletionWins && item.updatedAt.isAfter(exception.updatedAt)) {
          continue;
        }
        await _memoryItems.delete(item.id);
      }
    }
  }

  Future<void> _migrateGeneratedCopies() async {
    final today = dateOnly(DateTime.now());
    final memoryDeletions =
        await _sync?.memoryDeletions() ?? const <String, DateTime>{};
    final future = [
      for (final item in _memoryItems.state)
        if (item.isGeneratedOccurrence && item.memoryDate.isAfter(today)) item,
    ];
    if (future.isEmpty) return;
    final migrated = <RecurrenceOccurrenceException>[];
    final migratedIds = <String>{};
    final existingExceptions = {
      for (final exception in _exceptions.state) exception.id: exception,
    };
    for (final item in future) {
      final seriesId = item.seriesId;
      final series = seriesId == null ? null : _find(seriesId);
      if (series != null) {
        final sourceDate = occurrenceDateFromId(series.id, item.id);
        if (sourceDate == null || !isOccurrenceDate(series, sourceDate)) {
          continue;
        }
        final expected = occurrenceFromSeries(series, sourceDate);
        final wasMoved = dateKey(sourceDate) != dateKey(item.memoryDate);
        final exceptionId = recurrenceExceptionId(series.id, sourceDate);
        final existing = existingExceptions[exceptionId];
        final deletedAt = memoryDeletions[item.id];
        final hasDeletionSkip = _exceptions.state.any(
          (exception) =>
              exception.seriesId == series.id &&
              exception.isSkipped &&
              (exception.item?.id == item.id ||
                  (!wasMoved &&
                      dateKey(exception.occurrenceDate) ==
                          dateKey(sourceDate)) ||
                  (wasMoved &&
                      deletedAt != null &&
                      existing?.survivesMemoryDeletion != true &&
                      (dateKey(exception.occurrenceDate) ==
                              dateKey(sourceDate) ||
                          dateKey(exception.occurrenceDate) ==
                              dateKey(item.memoryDate)))),
        );
        final hasModifiedCopy = existing != null && !existing.isSkipped;
        final wasEdited = wasMoved || !_isUntouchedGenerated(item, expected);
        if (!hasDeletionSkip && (hasModifiedCopy || wasEdited)) {
          final markerItem = existing != null &&
                  !item.updatedAt.isAfter(existing.updatedAt) &&
                  existing.item != null
              ? existing.item!
              : item;
          final markerUpdatedAt = existing != null &&
                  existing.updatedAt.isAfter(markerItem.updatedAt)
              ? existing.updatedAt
              : markerItem.updatedAt;
          migrated.add(
            RecurrenceOccurrenceException(
              id: exceptionId,
              seriesId: series.id,
              occurrenceDate: dateOnly(sourceDate),
              kind: RecurrenceOccurrenceExceptionKind.modified,
              item: markerItem,
              survivesMemoryDeletion: true,
              createdAt: existing?.createdAt ?? markerItem.updatedAt,
              updatedAt: markerUpdatedAt,
            ),
          );
        }
        migratedIds.add(item.id);
      }
    }
    if (migratedIds.isEmpty) return;
    // Persist user changes before deleting legacy copies. A retry can safely
    // deduplicate both representations, while the opposite order can lose an
    // edited occurrence if the exception write fails.
    await _exceptions.upsertAll(migrated);
    await _memoryItems.removeMigratedRecurrenceCopies(migratedIds);
    final reset = [
      for (final series in state)
        series.copyWith(
          clearGeneratedThrough: true,
          historyThrough: today,
        ),
    ];
    await _repository.upsertAll(reset);
    state = reset;
  }

  Future<void> _materializeHistory(DateTime reference) async {
    final today = dateOnly(reference);
    const projection = RecurrenceProjectionService();
    final additions = <MemoryItem>[];
    final updatedSeries = <RecurrenceSeries>[];
    for (final series in state) {
      if (!series.isEnabled || series.startDate.isAfter(today)) continue;
      final start = series.historyThrough == null
          ? dateOnly(series.startDate)
          : dateOnly(series.historyThrough!).add(const Duration(days: 1));
      if (start.isAfter(today)) continue;
      additions.addAll(
        projection
            .itemsForRange(
              start: start,
              end: today,
              series: [series],
              exceptions: _exceptions.state,
              persistedItems: [..._memoryItems.state, ...additions],
            )
            .map((item) => item.copyWith(
                  createdAt: reference,
                  updatedAt: reference,
                )),
      );
      updatedSeries.add(
        series.copyWith(
          historyThrough: today,
          clearGeneratedThrough: true,
          updatedAt: reference,
        ),
      );
    }
    await _memoryItems.addAll(additions);
    if (updatedSeries.isNotEmpty) {
      await _repository.upsertAll(updatedSeries);
      final replacements = {for (final item in updatedSeries) item.id: item};
      state = [for (final item in state) replacements[item.id] ?? item];
      _sync?.recurrenceSeriesChanged();
    }
  }

  Future<void> _reconcileRecurringReminders() async {
    final now = DateTime.now();
    final end = safeDate(now.year, now.month + 6, now.day);
    final virtual = const RecurrenceProjectionService().itemsForRange(
      start: now,
      end: end,
      series: state,
      exceptions: _exceptions.state,
      persistedItems: _memoryItems.state,
    );
    try {
      await _reminders.reconcileRecurring(virtual);
    } catch (_) {
      // A later launch retries Android scheduling.
    }
  }

  bool _isUntouchedGenerated(MemoryItem item, MemoryItem expected) {
    return item.status == MemoryStatus.active &&
        item.type == expected.type &&
        item.title == expected.title &&
        item.body == expected.body &&
        item.timeMinutes == expected.timeMinutes &&
        item.remindAt == expected.remindAt &&
        item.reminderSoundUri == expected.reminderSoundUri &&
        item.reminderSoundName == expected.reminderSoundName &&
        item.priority == expected.priority &&
        _sameStrings(item.tags, expected.tags) &&
        item.projectId == expected.projectId &&
        _sameStrings(item.personIds, expected.personIds) &&
        item.placeId == expected.placeId &&
        item.audioPath == expected.audioPath &&
        item.audioDurationSeconds == expected.audioDurationSeconds &&
        _sameStrings(item.imagePaths, expected.imagePaths) &&
        item.transcript == expected.transcript &&
        item.amountMinor == expected.amountMinor &&
        item.paymentCategory == expected.paymentCategory &&
        item.birthYear == expected.birthYear;
  }

  bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  List<RecurrenceSeries> _replace(RecurrenceSeries value) => [
        for (final series in state)
          if (series.id == value.id) value else series,
        if (!state.any((series) => series.id == value.id)) value,
      ];

  RecurrenceSeries? _find(String id) {
    for (final series in state) {
      if (series.id == id) return series;
    }
    return null;
  }
}

List<DateTime> recurrenceDates(
  RecurrenceSeries series,
  DateTime reference, {
  DateTime? after,
}) {
  final requestedStart = after == null
      ? dateOnly(reference)
      : dateOnly(after).add(const Duration(days: 1));
  final start = latestDate(
    requestedStart,
    dateOnly(series.startDate).add(const Duration(days: 1)),
  );
  return recurrenceDatesInRange(
    series,
    start,
    recurrenceHorizon(reference),
  );
}

DateTime recurrenceHorizon(DateTime reference) =>
    safeDate(reference.year + 2, reference.month, reference.day);
