import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reproduces the exact stored state of the stuck subscription: the origin item
/// is alive, its series starts on the same day, there is no skip marker left,
/// and a tombstone from an earlier attempt still claims that marker is deleted.
class _Observer extends NoopSyncMutationObserver {
  _Observer(this.deletedMemory, this.deletedExceptions);

  final Map<String, DateTime> deletedMemory;
  final Map<String, DateTime> deletedExceptions;

  @override
  Future<void> memoryDeleted(String id, DateTime deletedAt) async {
    deletedMemory[id] = deletedAt;
  }

  @override
  Future<DateTime?> memoryDeletedAt(String id) async => deletedMemory[id];

  @override
  Future<Map<String, DateTime>> memoryDeletions() async =>
      Map.unmodifiable(deletedMemory);

  @override
  Future<void> recurrenceExceptionDeleted(String id, DateTime at) async {
    deletedExceptions[id] = at;
  }
}

void main() {
  const seriesId = 'recurrence_1787416988581941';
  const originId = '1787416988581941';
  final day = DateTime(2026, 8, 22);

  test('the stuck subscription can be deleted for good', () async {
    final created = DateTime(2026, 8, 22, 19, 43, 8);
    final updated = DateTime(2026, 8, 22, 19, 43, 58);
    final origin = MemoryItem(
      id: originId,
      type: MemoryType.payment,
      title: 'Тесть записи',
      body: 'Тесть записи',
      timeMinutes: 540,
      memoryDate: day,
      createdAt: created,
      updatedAt: updated,
      remindAt: DateTime(2026, 8, 19, 9),
      repeatRule: RecurrenceFrequency.monthly.name,
      seriesId: seriesId,
      amountMinor: 60000,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final series = RecurrenceSeries(
      id: seriesId,
      frequency: RecurrenceFrequency.monthly,
      template: origin,
      startDate: day,
      originItemId: originId,
      isEnabled: true,
      createdAt: created,
      updatedAt: updated,
      historyThrough: day,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': jsonEncode([origin.toJson()]),
      LocalRecurrenceRepository.storageKey: jsonEncode([series.toJson()]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });

    final memoryDeletions = <String, DateTime>{};
    final exceptionDeletions = <String, DateTime>{
      // The tombstone found in the user's storage.
      '$seriesId:20260822': DateTime(2026, 8, 22, 21, 51, 52),
    };
    final observer = _Observer(memoryDeletions, exceptionDeletions);

    final memories =
        MemoryItemsController(const LocalMemoryRepository(), null, null, observer);
    final exceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
      observer,
    );
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    final controller = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions,
      memories,
      reminders,
      observer,
    );
    await controller.load();

    final visible = const RecurrenceProjectionService().itemsForRange(
      start: day,
      end: day,
      series: controller.state,
      exceptions: exceptions.state,
      persistedItems: memories.state,
    );
    // Loading folds the record into its series, so it is projected rather
    // than stored as a row of its own.
    expect(memories.state, isEmpty);
    expect(visible.map((e) => e.id), contains(originId));

    await controller.deleteOccurrence(
      visible.firstWhere((e) => e.id == originId),
    );

    expect(memories.state.map((e) => e.id), isNot(contains(originId)),
        reason: 'nothing may be left behind');
    expect(exceptions.state, hasLength(1), reason: 'skip marker must exist');
    final marker = exceptions.state.single;
    expect(marker.id, '$seriesId:20260822');
    expect(marker.isSkipped, isTrue);
    expect(
      marker.updatedAt.isAfter(exceptionDeletions['$seriesId:20260822']!),
      isTrue,
      reason: 'the new marker must outrank the stale tombstone, otherwise the '
          'next sync deletes it again and the record returns',
    );

    // Restart.
    final memories2 = MemoryItemsController(
        const LocalMemoryRepository(), null, null, observer);
    final exceptions2 = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
      observer,
    );
    final reminders2 = NotificationService();
    addTearDown(reminders2.dispose);
    final controller2 = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions2,
      memories2,
      reminders2,
      observer,
    );
    await controller2.load();

    final after = const RecurrenceProjectionService().itemsForRange(
      start: day,
      end: day,
      series: controller2.state,
      exceptions: exceptions2.state,
      persistedItems: memories2.state,
    );
    expect(after, isEmpty, reason: 'nothing may be projected for that day');
    expect(memories2.state, isEmpty, reason: 'no row may be restored');
  });

  test('restoring a deleted occurrence leaves no tombstone on its marker',
      () async {
    final created = DateTime(2026, 8, 22, 19, 43, 8);
    final origin = MemoryItem(
      id: originId,
      type: MemoryType.payment,
      title: 'Тесть записи',
      body: 'Тесть записи',
      timeMinutes: 540,
      memoryDate: day,
      createdAt: created,
      updatedAt: created,
      repeatRule: RecurrenceFrequency.monthly.name,
      seriesId: seriesId,
      amountMinor: 60000,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final series = RecurrenceSeries(
      id: seriesId,
      frequency: RecurrenceFrequency.monthly,
      template: origin,
      startDate: DateTime(2026, 5, 22),
      originItemId: originId,
      isEnabled: true,
      createdAt: created,
      updatedAt: created,
      historyThrough: day,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': '[]',
      LocalRecurrenceRepository.storageKey: jsonEncode([series.toJson()]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });

    final exceptionDeletions = <String, DateTime>{};
    final observer = _Observer(<String, DateTime>{}, exceptionDeletions);
    final memories = MemoryItemsController(
        const LocalMemoryRepository(), null, null, observer);
    final exceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
      observer,
    );
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    final controller = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions,
      memories,
      reminders,
      observer,
    );
    await controller.load();

    final projected = occurrenceFromSeries(controller.state.single, day);
    await controller.deleteOccurrence(projected);
    expect(exceptions.state.single.isSkipped, isTrue);

    // The user brings that occurrence back by editing it again.
    await controller.saveOccurrenceOverride(
      projected.copyWith(title: 'Вернул', body: 'Вернул'),
      occurrenceDate: day,
    );

    expect(
      exceptionDeletions,
      isEmpty,
      reason: 'superseding a deletion marker must not record a tombstone that '
          'would defeat the next deletion of the same occurrence',
    );
    expect(exceptions.state.single.isSkipped, isFalse,
        reason: 'the marker is superseded, not skipped');
  });
}
