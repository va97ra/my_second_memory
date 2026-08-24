import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seriesId = 'sub-series';
const _originId = 'sub-origin';

class _Device {
  _Device(this.memories, this.exceptions, this.controller);

  final MemoryItemsController memories;
  final RecurrenceExceptionController exceptions;
  final RecurrenceSeriesController controller;

  /// Mirrors what the month tab renders for [date]: the projection plus every
  /// persisted occurrence that is not covered by a skip marker.
  List<MemoryItem> visibleOn(DateTime date) {
    final projected = const RecurrenceProjectionService().itemsForRange(
      start: date,
      end: date,
      series: controller.state,
      exceptions: exceptions.state,
      persistedItems: memories.state,
    );
    final index = RecurrenceOccurrenceIndex(
      series: controller.state,
      exceptions: exceptions.state,
    );
    final byId = <String, MemoryItem>{
      for (final item in projected)
        if (!item.isArchived) item.id: item,
    };
    for (final item in memories.state) {
      if (item.isArchived || item.seriesId == null) continue;
      if (index.isSkippedPersisted(item)) continue;
      if (dateKey(item.memoryDate) != dateKey(date)) continue;
      byId[item.id] = item;
    }
    return byId.values.toList();
  }
}

Future<_Device> _launch() async {
  final memories = MemoryItemsController(const LocalMemoryRepository());
  final exceptions = RecurrenceExceptionController(
    const LocalRecurrenceExceptionRepository(),
  );
  final reminders = NotificationService();
  addTearDown(reminders.dispose);
  final controller = RecurrenceSeriesController(
    const LocalRecurrenceRepository(),
    exceptions,
    memories,
    reminders,
  );
  await controller.load();
  return _Device(memories, exceptions, controller);
}

DateTime _shiftMonths(DateTime anchor, int delta) =>
    safeDate(anchor.year, anchor.month + delta, anchor.day);

void main() {
  final today = dateOnly(DateTime.now());
  final start = _shiftMonths(today, -3);

  MemoryItem origin() => MemoryItem(
        id: _originId,
        type: MemoryType.payment,
        title: 'Подписка',
        body: 'Подписка',
        timeMinutes: 9 * 60,
        memoryDate: start,
        createdAt: start,
        updatedAt: start,
        amountMinor: 60000,
        paymentCategory: PaymentCategory.subscription.name,
        seriesId: _seriesId,
        repeatRule: RecurrenceFrequency.monthly.name,
      );

  RecurrenceSeries series({DateTime? historyThrough}) => RecurrenceSeries(
        id: _seriesId,
        frequency: RecurrenceFrequency.monthly,
        template: origin(),
        startDate: start,
        originItemId: _originId,
        createdAt: start,
        updatedAt: start,
        historyThrough: historyThrough,
      );

  RecurrenceOccurrenceException skipFor(DateTime date, DateTime deletedAt) {
    return RecurrenceOccurrenceException(
      id: recurrenceExceptionId(_seriesId, date),
      seriesId: _seriesId,
      occurrenceDate: date,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      item: occurrenceFromSeries(series(), date),
      createdAt: deletedAt,
      updatedAt: deletedAt,
    );
  }

  void seed({
    DateTime? historyThrough,
    List<RecurrenceOccurrenceException> exceptions = const [],
  }) {
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': jsonEncode([origin().toJson()]),
      LocalRecurrenceRepository.storageKey:
          jsonEncode([series(historyThrough: historyThrough).toJson()]),
      LocalRecurrenceExceptionRepository.storageKey:
          jsonEncode([for (final item in exceptions) item.toJson()]),
    });
  }

  test(
      'materializing history does not resurrect an occurrence deleted on '
      'another device', () async {
    // The other device deleted today's occurrence an hour ago and uploaded the
    // skip marker. This device has not been opened for two months, so it still
    // materializes that day before the pull delivers the marker.
    final deletedAt = DateTime.now().subtract(const Duration(hours: 1));
    seed(historyThrough: _shiftMonths(today, -2));

    final device = await _launch();
    expect(device.visibleOn(today), hasLength(1));

    await device.exceptions.replaceAll([skipFor(today, deletedAt)]);
    await device.controller.reconcileOriginOverrides();

    expect(
      device.visibleOn(today).map((item) => item.id).toList(),
      isEmpty,
      reason: 'a launch must not outrank a deletion recorded elsewhere',
    );
    expect(
      device.memories.state.map((item) => item.id),
      isNot(contains(occurrenceId(_seriesId, today))),
      reason: 'the cached row must be dropped, not just hidden',
    );
  });

  test('a recurring occurrence is never materialized into a row', () async {
    seed(historyThrough: _shiftMonths(today, -2));

    final device = await _launch();

    expect(device.visibleOn(today), hasLength(1),
        reason: 'it is still shown, from the projection');
    expect(
      device.memories.state.where((item) => item.isGeneratedOccurrence),
      isEmpty,
      reason: 'a launch must not write occurrence rows that later disagree '
          'with the markers about what an occurrence is',
    );
  });

  test('an edited occurrence still wins over an older deletion marker',
      () async {
    final deletedAt = DateTime.now().subtract(const Duration(hours: 1));
    seed(historyThrough: _shiftMonths(today, -2));

    final device = await _launch();
    // The engine reads local state, then goes to the network. The edit lands
    // while that request is in flight, so it must survive the merge.
    final baseline = [...device.exceptions.state];
    await device.controller.saveOccurrenceOverride(
      device.visibleOn(today).single.copyWith(
            title: 'Оплачено картой',
            body: 'Оплачено картой',
          ),
      occurrenceDate: today,
    );

    await device.exceptions.replaceAllFromSync(
      [skipFor(today, deletedAt)],
      baseline: baseline,
    );
    await device.controller.reconcileOriginOverrides();

    expect(
      device.visibleOn(today).map((item) => item.title).toList(),
      ['Оплачено картой'],
      reason: 'a real user edit is newer than the marker and must survive',
    );
  });

  test('a deleted occurrence stays deleted across a restart', () async {
    final deletedAt = DateTime.now().subtract(const Duration(hours: 1));
    seed(exceptions: [skipFor(today, deletedAt)]);

    final device = await _launch();

    expect(device.visibleOn(today).map((item) => item.id).toList(), isEmpty);
    expect(
      device.visibleOn(_shiftMonths(today, -1)),
      hasLength(1),
      reason: 'neighbouring occurrences must be untouched',
    );
  });
}
