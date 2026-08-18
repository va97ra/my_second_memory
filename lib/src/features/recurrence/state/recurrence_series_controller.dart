import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_status.dart';
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
    await _sync?.recurrenceSeriesDeleted(seriesId, now);
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
    final cutoff = dateOnly(occurrenceDate ?? edited.memoryDate);
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
    final sourceDate = dateOnly(occurrenceDate ?? item.memoryDate);
    final normalized = item.copyWith(
      id: occurrenceId(seriesId, sourceDate),
      isGeneratedOccurrence: true,
      updatedAt: DateTime.now(),
    );
    if (!dateOnly(item.memoryDate).isAfter(dateOnly(DateTime.now()))) {
      if (_memoryItems.state.any((entry) => entry.id == normalized.id)) {
        await _memoryItems.update(normalized);
      } else {
        await _memoryItems.add(normalized);
      }
      if (dateKey(sourceDate) == dateKey(item.memoryDate)) {
        await _exceptions.delete(seriesId, sourceDate);
      } else {
        await _exceptions.skip(seriesId, sourceDate);
      }
    } else {
      final now = DateTime.now();
      await _exceptions.upsert(
        RecurrenceOccurrenceException(
          id: recurrenceExceptionId(seriesId, sourceDate),
          seriesId: seriesId,
          occurrenceDate: sourceDate,
          kind: RecurrenceOccurrenceExceptionKind.modified,
          item: normalized,
          createdAt: now,
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
    await _memoryItems.delete(item.id);
    await _exceptions.skip(seriesId, item.memoryDate);
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> deleteSeries(String id) async {
    await _loadFuture;
    for (final item in [..._memoryItems.state]) {
      if (item.seriesId == id) await _memoryItems.delete(item.id);
    }
    await _exceptions.deleteSeries(id);
    await _repository.delete(id);
    state = [
      for (final series in state)
        if (series.id != id) series
    ];
    await _sync?.recurrenceSeriesDeleted(id, DateTime.now());
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> deleteFromDate(String id, DateTime from) async {
    await _loadFuture;
    final current = _find(id);
    if (current == null) return;
    final cutoff = dateOnly(from);
    final updated = current.copyWith(
      endDate: cutoff.subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
    state = _replace(updated);
    _sync?.recurrenceSeriesChanged();
    for (final item in [..._memoryItems.state]) {
      if (item.seriesId == id && !item.memoryDate.isBefore(cutoff)) {
        await _memoryItems.delete(item.id);
      }
    }
    for (final exception in [..._exceptions.state]) {
      if (exception.seriesId == id &&
          !exception.occurrenceDate.isBefore(cutoff)) {
        await _exceptions.delete(id, exception.occurrenceDate);
      }
    }
    unawaited(_reconcileRecurringReminders());
  }

  Future<void> replaceAll(List<RecurrenceSeries> series) async {
    await _loadFuture;
    await _repository.replaceAll(series);
    state = series;
    await _migrateGeneratedCopies();
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

  Future<void> _migrateGeneratedCopies() async {
    final today = dateOnly(DateTime.now());
    final future = [
      for (final item in _memoryItems.state)
        if (item.isGeneratedOccurrence && item.memoryDate.isAfter(today)) item,
    ];
    if (future.isEmpty) return;
    final migrated = <RecurrenceOccurrenceException>[];
    final now = DateTime.now();
    final futureIds = {for (final item in future) item.id};
    for (final item in future) {
      final seriesId = item.seriesId;
      final series = seriesId == null ? null : _find(seriesId);
      if (series != null) {
        final expected = occurrenceFromSeries(series, item.memoryDate);
        if (!_isUntouchedGenerated(item, expected)) {
          migrated.add(
            RecurrenceOccurrenceException(
              id: recurrenceExceptionId(series.id, item.memoryDate),
              seriesId: series.id,
              occurrenceDate: dateOnly(item.memoryDate),
              kind: RecurrenceOccurrenceExceptionKind.modified,
              item: item,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
    }
    await _memoryItems.replaceAll([
      for (final item in _memoryItems.state)
        if (!futureIds.contains(item.id)) item,
    ]);
    await _exceptions.upsertAll(migrated);
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
