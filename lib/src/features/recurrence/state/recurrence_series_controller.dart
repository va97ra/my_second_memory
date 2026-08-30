import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import '../../memory_items/memory_items.dart';
import 'package:ez_data/ez_data.dart';
import 'recurrence_exception_controller.dart';
import 'recurrence_legacy_repair.dart';

class RecurrenceSeriesController extends StateNotifier<List<RecurrenceSeries>>
    implements RecurrenceRepairHost {
  RecurrenceSeriesController(
      this._repository, this._exceptions, this._memoryItems, this._reminders,
      [this._sync])
      : super(const []) {
    _legacyRepair = RecurrenceLegacyRepair(
      host: this,
      repository: _repository,
      exceptions: _exceptions,
      memoryItems: _memoryItems,
      sync: _sync,
    );
    _loadFuture = _load();
  }

  final RecurrenceRepository _repository;
  final RecurrenceExceptionController _exceptions;
  final MemoryItemsController _memoryItems;
  final ReminderScheduler _reminders;
  final SyncMutationObserver? _sync;
  late final Future<void> _loadFuture;
  late final RecurrenceLegacyRepair _legacyRepair;

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    await Future.wait([_memoryItems.load(), _exceptions.load()]);
    state = await _repository.loadAll();
    await _legacyRepair.runOnLoad();
    unawaited(_reconcileRecurringReminders());
  }

  Future<RecurrenceSeries> setFrequency(
    MemoryItem item,
    RecurrenceFrequency frequency,
  ) async {
    await _loadFuture;
    final now = DateTime.now();
    final series = RecurrenceSeries.forRecord(
      record: item,
      frequency: frequency,
      now: now,
      existing: _find(item.seriesId ?? 'recurrence_${item.id}'),
    );
    await _repository.upsert(series);
    state = _replace(series);
    _sync?.recurrenceSeriesChanged();
    // Write the series before retiring the row, so an interruption can never
    // leave the record with no representation at all.
    await _retireOriginRow(series);
    unawaited(_reconcileRecurringReminders());
    return series;
  }

  /// Drops the standalone row a recurring record used to keep beside its
  /// series. The template is the record now and the first occurrence is
  /// projected from it, so a row would only be a second copy able to disagree.
  Future<void> _retireOriginRow(RecurrenceSeries series) async {
    if (!_memoryItems.state.any((item) => item.id == series.originItemId)) {
      return;
    }
    await _memoryItems.retireRow(series.originItemId);
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
    // The series held the record, so hand it back a standalone row before the
    // series goes. Without this the record would have no representation left.
    final series = _find(seriesId);
    if (series != null) {
      final restored = item.copyWith(
        id: series.originItemId,
        clearSeries: true,
        clearRepeatRule: true,
        isGeneratedOccurrence: false,
        updatedAt: now,
      );
      if (_memoryItems.state.any((entry) => entry.id == restored.id)) {
        await _memoryItems.update(restored);
      } else {
        await _memoryItems.add(restored);
      }
    }
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
    // Срез считается по исходной дате вхождения: перенесённое вхождение видно
    // на новой дате, но серия делится по той, откуда оно родом.
    final cutoff = _sourceDateForItem(edited, occurrenceDate);
    final split = splitSeriesForFutureEdit(
      current: current,
      edited: edited,
      cutoff: cutoff,
      now: now,
    );

    if (!split.splits) {
      await _repository.upsert(split.replacement);
      state = _replace(split.replacement);
      _sync?.recurrenceSeriesChanged();
      await _retireOriginRow(split.replacement);
      unawaited(_reconcileRecurringReminders());
      return split.replacement;
    }

    await _repository.upsertAll([split.ended!, split.replacement]);
    state = [..._replace(split.ended!), split.replacement];
    _sync?.recurrenceSeriesChanged();
    await _retireOriginRow(split.replacement);
    // Переопределение на дате среза принадлежало прежней серии; новая серия
    // начинается с самой правки, и старая отметка только спорила бы с ней.
    final cutoffMarker = recurrenceExceptionId(currentId, cutoff);
    if (_exceptions.exceptions.any((item) => item.id == cutoffMarker)) {
      await _exceptions.delete(currentId, cutoff);
    }
    unawaited(_reconcileRecurringReminders());
    return split.replacement;
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
    // An occurrence override lives in exactly one place: the exception for its
    // source date. Nothing is materialized any more, so no persisted row can
    // disagree with the marker about what this occurrence is.
    final normalized = item.copyWith(
      id: series == null
          ? occurrenceId(seriesId, sourceDate)
          : occurrenceIdFor(series, sourceDate),
      isGeneratedOccurrence: true,
      updatedAt: DateTime.now(),
    );
    final exceptionId = recurrenceExceptionId(seriesId, sourceDate);
    RecurrenceOccurrenceException? existing;
    for (final exception in _exceptions.state) {
      if (exception.id == exceptionId) {
        existing = exception;
        break;
      }
    }
    final now = DateTime.now();
    final hasLegacyRow =
        _memoryItems.state.any((entry) => entry.id == normalized.id);
    await _exceptions.upsert(
      RecurrenceOccurrenceException(
        id: exceptionId,
        seriesId: seriesId,
        occurrenceDate: sourceDate,
        kind: RecurrenceOccurrenceExceptionKind.modified,
        item: normalized,
        // Dropping the legacy row below records a deletion tombstone for its
        // id. This marker takes that row's place, so it has to outlive it.
        survivesMemoryDeletion:
            hasLegacyRow || existing?.survivesMemoryDeletion == true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    if (hasLegacyRow) {
      await _memoryItems.delete(normalized.id);
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
    await deleteMiskeyedOverrides(item, sourceDate);
    await writeDeletionMarker(item, sourceDate);
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
    await _replaceAllAndReconcile(mergeSyncedEntities(
      incoming: series,
      current: state,
      baseline: baseline,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
    ));
  }

  Future<void> _replaceAllAndReconcile(List<RecurrenceSeries> series) async {
    await _repository.replaceAll(series);
    state = series;
    // Синхронизация могла привезти данные со старой сборки, поэтому после
    // подмены состояния проходы ремонта нужны так же, как при загрузке.
    await _legacyRepair.runOnLoad();
    unawaited(_reconcileRecurringReminders());
  }

  /// Разрешение любого представления вхождения к его исходной дате.
  ///
  /// Правило живёт в домене: перенесённое вхождение видно на новой дате, но
  /// адресуется по исходной, иначе серия разъезжается надвое. Здесь только
  /// доставка сегодняшних серий и отметок.
  RecurrenceOccurrenceIndex get _occurrenceIndex => RecurrenceOccurrenceIndex(
        series: state,
        exceptions: _exceptions.exceptions,
      );

  DateTime _sourceDateForItem(MemoryItem item, [DateTime? fallback]) =>
      _occurrenceIndex.sourceDateFor(item, fallback: fallback);

  Future<void> reconcileOriginOverrides() async {
    await _loadFuture;
    await _legacyRepair.reconcileOriginOverrides();
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

  List<RecurrenceSeries> _replace(RecurrenceSeries value) => [
        for (final series in state)
          if (series.id == value.id) value else series,
        if (!state.any((series) => series.id == value.id)) value,
      ];

  @override
  Future<void> writeDeletionMarker(
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

  @override
  Future<void> deleteMiskeyedOverrides(
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

  RecurrenceSeries? _find(String id) {
    for (final series in state) {
      if (series.id == id) return series;
    }
    return null;
  }

  // Доступ, которым пользуется ремонт старых данных.

  @override
  List<RecurrenceSeries> get series => state;

  @override
  void replaceSeries(List<RecurrenceSeries> value) => state = value;

  @override
  RecurrenceSeries? findSeries(String id) => _find(id);

  @override
  DateTime sourceDateFor(MemoryItem item, [DateTime? fallback]) =>
      _sourceDateForItem(item, fallback);

  @override
  Future<void> retireOriginRow(RecurrenceSeries series) =>
      _retireOriginRow(series);
}
