import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async/sequential_task_queue.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../notifications/data/notification_service.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_status.dart';
import '../../security/data/encrypted_json_store.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../security/state/security_provider.dart';
import '../data/encrypted_recurrence_repository.dart';
import '../data/recurrence_repository.dart';
import '../data/recurrence_repository_factory.dart';
import '../domain/recurrence_series.dart';

final plainRecurrenceRepositoryProvider = Provider<RecurrenceRepository>((ref) {
  final repository = createRecurrenceRepository();
  ref.onDispose(() => unawaited(repository.close()));
  return repository;
});

final recurrenceRepositoryProvider = Provider<RecurrenceRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final plain = ref.watch(plainRecurrenceRepositoryProvider);
  if (session.hasPin && session.cipher != null) {
    final memoryBackend = ref.watch(plainMemoryRepositoryProvider);
    final backend = memoryBackend is SecureEntityBackend
        ? memoryBackend as SecureEntityBackend
        : null;
    return EncryptedRecurrenceRepository(
      store: EncryptedJsonStore(cipher: session.cipher!),
      plainRepository: plain,
      backend: backend,
    );
  }
  return plain;
});

final recurrenceSeriesControllerProvider =
    StateNotifierProvider<RecurrenceSeriesController, List<RecurrenceSeries>>(
  (ref) => RecurrenceSeriesController(
    ref.watch(recurrenceRepositoryProvider),
    ref.watch(memoryItemsControllerProvider.notifier),
    ref.watch(notificationServiceProvider),
  ),
);

final recurrenceLoadProvider = FutureProvider<void>((ref) {
  return ref.watch(recurrenceSeriesControllerProvider.notifier).load();
});

final recurrenceSeriesByIdProvider =
    Provider.family<RecurrenceSeries?, String>((ref, id) {
  for (final series in ref.watch(recurrenceSeriesControllerProvider)) {
    if (series.id == id) return series;
  }
  return null;
});

final recurringUpcomingItemsProvider =
    Provider.family<List<MemoryItem>, RecurrenceFrequency>((ref, frequency) {
  final enabledSeriesIds = {
    for (final series in ref.watch(recurrenceSeriesControllerProvider))
      if (series.isEnabled && series.frequency == frequency) series.id,
  };
  final today = _dateOnly(DateTime.now());
  final horizon = recurrenceHorizon(today);
  final items = [
    for (final item in ref.watch(memoryItemsControllerProvider))
      if (item.seriesId != null &&
          enabledSeriesIds.contains(item.seriesId) &&
          !item.memoryDate.isBefore(today) &&
          !item.memoryDate.isAfter(horizon))
        item,
  ];
  items.sort((left, right) {
    final byDate = left.memoryDate.compareTo(right.memoryDate);
    if (byDate != 0) return byDate;
    return (left.timeMinutes ?? 24 * 60)
        .compareTo(right.timeMinutes ?? 24 * 60);
  });
  return items;
});

class RecurrenceSeriesController extends StateNotifier<List<RecurrenceSeries>> {
  RecurrenceSeriesController(
      this._repository, this._memoryItems, this._reminders)
      : super(const []) {
    _loadFuture = _load();
  }

  final RecurrenceRepository _repository;
  final MemoryItemsController _memoryItems;
  final ReminderScheduler _reminders;
  late final Future<void> _loadFuture;
  final _generationQueue = SequentialTaskQueue();

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    await _memoryItems.load();
    state = await _repository.loadAll();
    unawaited(_enqueueEnsure(DateTime.now()));
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
    await _memoryItems.update(linked);
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
      generatedThrough:
          existing?.frequency == frequency ? existing?.generatedThrough : null,
    );
    await _repository.upsert(series);
    state = _replace(series);
    unawaited(_enqueueEnsure(DateTime.now(), onlySeries: series));
    return series;
  }

  Future<void> clearFrequency(MemoryItem item) async {
    await _loadFuture;
    final seriesId = item.seriesId;
    if (seriesId == null) return;
    final now = DateTime.now();
    final today = _dateOnly(now);
    for (final occurrence in [..._memoryItems.state]) {
      if (occurrence.seriesId != seriesId) continue;
      if (occurrence.isGeneratedOccurrence &&
          occurrence.memoryDate.isAfter(today)) {
        await _memoryItems.delete(occurrence.id);
      } else {
        await _memoryItems.update(
          occurrence.copyWith(
            clearSeries: true,
            clearRepeatRule: true,
            isGeneratedOccurrence: false,
            updatedAt: now,
          ),
        );
      }
    }
    await _repository.delete(seriesId);
    state = [
      for (final series in state)
        if (series.id != seriesId) series
    ];
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
    if (enabled) {
      unawaited(_enqueueEnsure(DateTime.now(), onlySeries: updated));
    }
    for (final item in _memoryItems.state) {
      if (item.seriesId != id || !item.isGeneratedOccurrence) continue;
      try {
        if (enabled && item.remindAt != null) {
          await _reminders.schedule(item);
        } else {
          await _reminders.cancel(item.id);
        }
      } catch (_) {
        // Local series state remains authoritative if Android rejects alarms.
      }
    }
  }

  Future<void> applyToFuture(MemoryItem edited) async {
    await _loadFuture;
    final id = edited.seriesId;
    if (id == null) return;
    final current = _find(id);
    if (current == null) return;
    final now = DateTime.now();
    final series = current.copyWith(template: edited, updatedAt: now);
    await _repository.upsert(series);
    state = _replace(series);

    for (final occurrence in [..._memoryItems.state]) {
      if (occurrence.seriesId != id ||
          !occurrence.memoryDate.isAfter(edited.memoryDate)) {
        continue;
      }
      await _memoryItems.update(
        _occurrenceFromTemplate(
          series,
          occurrence.memoryDate,
          id: occurrence.id,
          createdAt: occurrence.createdAt,
          status: occurrence.status,
        ),
      );
    }
  }

  Future<void> deleteSeries(String id) async {
    await _loadFuture;
    for (final item in [..._memoryItems.state]) {
      if (item.seriesId == id) await _memoryItems.delete(item.id);
    }
    await _repository.delete(id);
    state = [
      for (final series in state)
        if (series.id != id) series
    ];
  }

  Future<void> deleteFromDate(String id, DateTime from) async {
    await _loadFuture;
    final current = _find(id);
    if (current == null) return;
    final cutoff = _dateOnly(from);
    final disabled = current.copyWith(
      isEnabled: false,
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(disabled);
    state = _replace(disabled);
    for (final item in [..._memoryItems.state]) {
      if (item.seriesId == id && !item.memoryDate.isBefore(cutoff)) {
        await _memoryItems.delete(item.id);
      }
    }
  }

  Future<void> replaceAll(List<RecurrenceSeries> series) async {
    await _loadFuture;
    await _repository.replaceAll(series);
    state = series;
    await _enqueueEnsure(DateTime.now());
  }

  Future<void> ensureOccurrences() async {
    await _loadFuture;
    await _enqueueEnsure(DateTime.now());
  }

  Future<void> ensureHorizonFor(DateTime visibleMonth) async {
    await _loadFuture;
    final now = DateTime.now();
    final visible = DateTime(visibleMonth.year, visibleMonth.month);
    final current = DateTime(now.year, now.month);
    if (visible.isBefore(current)) return;
    await _enqueueEnsure(visible);
  }

  Future<void> _enqueueEnsure(
    DateTime reference, {
    RecurrenceSeries? onlySeries,
  }) {
    return _generationQueue.add(() async {
      final generated = <MemoryItem>[];
      final updatedSeries = <RecurrenceSeries>[];
      final targets =
          onlySeries == null ? state : <RecurrenceSeries>[onlySeries];
      final existingDatesBySeries = <String, Set<int>>{};
      for (final item in _memoryItems.state) {
        final seriesId = item.seriesId;
        if (seriesId == null) continue;
        (existingDatesBySeries[seriesId] ??= <int>{})
            .add(_dateKey(item.memoryDate));
      }
      for (final series in targets) {
        if (!series.isEnabled || !_needsExtension(series, reference)) continue;
        final existingDates = existingDatesBySeries[series.id] ?? <int>{};
        existingDates.add(_dateKey(series.startDate));
        generated.addAll(
          _missingOccurrences(series, reference, existingDates),
        );
        updatedSeries.add(
          series.copyWith(
            generatedThrough: recurrenceHorizon(reference),
            updatedAt: DateTime.now(),
          ),
        );
      }
      await _memoryItems.addAll(generated);
      if (updatedSeries.isNotEmpty) {
        await _repository.upsertAll(updatedSeries);
        final replacements = {for (final item in updatedSeries) item.id: item};
        state = [
          for (final series in state) replacements[series.id] ?? series,
        ];
      }
    });
  }

  bool _needsExtension(RecurrenceSeries series, DateTime reference) {
    final preparedThrough = series.generatedThrough;
    if (preparedThrough == null) return true;
    final thresholdMonths =
        series.frequency == RecurrenceFrequency.monthly ? 3 : 6;
    final extensionThreshold = _safeDate(
      reference.year,
      reference.month + thresholdMonths,
      reference.day,
    );
    return preparedThrough.isBefore(extensionThreshold);
  }

  List<MemoryItem> _missingOccurrences(
    RecurrenceSeries series,
    DateTime reference,
    Set<int> existingDates,
  ) {
    final missing = <MemoryItem>[];
    for (final date in recurrenceDates(
      series,
      reference,
      after: series.generatedThrough,
    )) {
      if (!existingDates.add(_dateKey(date))) continue;
      missing.add(_occurrenceFromTemplate(series, date));
    }
    return missing;
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
  DateTime now, {
  DateTime? after,
}) {
  final dates = <DateTime>[];
  final anchor = _dateOnly(series.startDate);
  final firstAllowed = _latestDate(
      _dateOnly(now),
      after == null
          ? _dateOnly(now)
          : _dateOnly(after).add(const Duration(days: 1)));
  final horizon = recurrenceHorizon(now);
  switch (series.frequency) {
    case RecurrenceFrequency.monthly:
      var index = (firstAllowed.year - anchor.year) * 12 +
          firstAllowed.month -
          anchor.month;
      if (index < 1) index = 1;
      for (;; index++) {
        final month = DateTime(anchor.year, anchor.month + index);
        final date = _safeDate(month.year, month.month, anchor.day);
        if (date.isAfter(horizon)) break;
        if (date.isBefore(firstAllowed)) continue;
        dates.add(date);
      }
    case RecurrenceFrequency.yearly:
      var firstYear = firstAllowed.year;
      if (firstYear <= anchor.year) firstYear = anchor.year + 1;
      for (var year = firstYear; year <= horizon.year; year++) {
        final date = _safeDate(year, anchor.month, anchor.day);
        if (!date.isAfter(horizon) && !date.isBefore(firstAllowed)) {
          dates.add(date);
        }
      }
  }
  return dates;
}

DateTime recurrenceHorizon(DateTime reference) => _safeDate(
      reference.year + 2,
      reference.month,
      reference.day,
    );

MemoryItem _occurrenceFromTemplate(
  RecurrenceSeries series,
  DateTime date, {
  String? id,
  DateTime? createdAt,
  MemoryStatus status = MemoryStatus.active,
}) {
  final template = series.template;
  final now = DateTime.now();
  final reminder = _shiftReminder(template, date, now);
  return template.copyWith(
    id: id ?? '${series.id}_${_dateKey(date)}',
    memoryDate: date,
    status: status,
    createdAt: createdAt ?? now,
    updatedAt: now,
    remindAt: reminder,
    clearReminder: reminder == null,
    seriesId: series.id,
    repeatRule: series.frequency.name,
    isGeneratedOccurrence: true,
  );
}

DateTime? _shiftReminder(MemoryItem template, DateTime date, DateTime now) {
  final source = template.remindAt;
  if (source == null) return null;
  final eventMinutes = template.timeMinutes ?? 9 * 60;
  final sourceEvent = DateTime(
    template.memoryDate.year,
    template.memoryDate.month,
    template.memoryDate.day,
    eventMinutes ~/ 60,
    eventMinutes % 60,
  );
  final offset = sourceEvent.difference(source);
  final target = DateTime(
    date.year,
    date.month,
    date.day,
    eventMinutes ~/ 60,
    eventMinutes % 60,
  ).subtract(offset);
  return target.isAfter(now) ? target : null;
}

DateTime _safeDate(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _dateKey(DateTime value) =>
    value.year * 10000 + value.month * 100 + value.day;

DateTime _latestDate(DateTime left, DateTime right) =>
    left.isAfter(right) ? left : right;
