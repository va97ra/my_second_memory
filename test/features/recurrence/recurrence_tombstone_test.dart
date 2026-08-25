import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recurrence_test_support.dart';

void main() {
  test('memory tombstone defeats stale moved markers downloaded from cloud',
      () async {
    final createdAt = DateTime(2026, 1, 1, 10);
    final sourceDate = DateTime(2099, 1, 9);
    final movedDate = DateTime(2099, 2, 9);
    final moved = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Удалённая встреча',
      memoryDate: movedDate,
      createdAt: createdAt,
      updatedAt: createdAt.add(const Duration(minutes: 1)),
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: moved.copyWith(memoryDate: sourceDate),
      startDate: sourceDate,
      originItemId: moved.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final modified = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, sourceDate),
      seriesId: series.id,
      occurrenceDate: sourceDate,
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: moved,
      createdAt: moved.updatedAt,
      updatedAt: moved.updatedAt,
    );
    final legacyDestinationSkip = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, movedDate),
      seriesId: series.id,
      occurrenceDate: movedDate,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      createdAt: moved.updatedAt.add(const Duration(minutes: 1)),
      updatedAt: moved.updatedAt.add(const Duration(minutes: 1)),
    );
    final deletedAt = moved.updatedAt.add(const Duration(minutes: 1));
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': '[]',
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey:
          encodeExceptions([modified, legacyDestinationSkip]),
    });
    final sync = DeletionObserver({moved.id: deletedAt});
    final memories = MemoryItemsController(
      const LocalMemoryRepository(),
      null,
      null,
      sync,
    );
    final exceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
      sync,
    );
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    final controller = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions,
      memories,
      reminders,
      sync,
    );

    await controller.load();

    expect(memories.state, isEmpty);
    final sourceMarker = exceptions.state.singleWhere(
      (entry) => dateKey(entry.occurrenceDate) == dateKey(sourceDate),
    );
    expect(sourceMarker.isSkipped, isTrue);
    expect(sourceMarker.item?.id, moved.id);
    expect(
      const RecurrenceProjectionService().itemsForRange(
        start: sourceDate,
        end: movedDate,
        series: controller.state,
        exceptions: exceptions.state,
        persistedItems: memories.state,
      ),
      isEmpty,
    );
  });

  test('past moved occurrence survives reload and stays deleted afterwards',
      () async {
    final today = dateOnly(DateTime.now());
    final sourceDate = DateTime(today.year - 1, 5, 12);
    final movedDate = sourceDate.add(const Duration(days: 2));
    final startDate = DateTime(sourceDate.year - 1, 5, 12);
    final createdAt = DateTime(today.year - 2, 1, 1, 10);
    final origin = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Встреча',
      memoryDate: startDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: origin,
      startDate: startDate,
      originItemId: origin.id,
      createdAt: createdAt,
      updatedAt: createdAt,
      historyThrough: today,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([origin]),
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });

    Future<({
      RecurrenceSeriesController controller,
      RecurrenceExceptionController exceptions,
      MemoryItemsController memories,
    })> loadControllers() async {
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
      return (
        controller: controller,
        exceptions: exceptions,
        memories: memories,
      );
    }

    final first = await loadControllers();
    final moved = occurrenceFromSeries(series, sourceDate).copyWith(
      memoryDate: movedDate,
      body: 'Перенесено',
    );
    await first.controller.saveOccurrenceOverride(
      moved,
      occurrenceDate: sourceDate,
    );

    final reloaded = await loadControllers();
    // The moved occurrence lives in its exception only; nothing about it is
    // materialized into a memory row any more.
    expect(
      reloaded.memories.state.map((item) => item.id),
      isNot(contains(occurrenceId(series.id, sourceDate))),
    );
    expect(reloaded.exceptions.state.single.isSkipped, isFalse);
    final movedOccurrence = const RecurrenceProjectionService()
        .itemsForRange(
          start: sourceDate,
          end: movedDate,
          series: reloaded.controller.state,
          exceptions: reloaded.exceptions.state,
          persistedItems: reloaded.memories.state,
        )
        .single;
    expect(movedOccurrence.memoryDate, movedDate);

    await reloaded.controller.deleteOccurrence(movedOccurrence);
    final afterDelete = await loadControllers();

    expect(
      afterDelete.memories.state.map((item) => item.id),
      isNot(contains(movedOccurrence.id)),
    );
    expect(afterDelete.exceptions.state.single.isSkipped, isTrue);
    expect(
      const RecurrenceProjectionService().itemsForRange(
        start: sourceDate,
        end: movedDate,
        series: afterDelete.controller.state,
        exceptions: afterDelete.exceptions.state,
        persistedItems: afterDelete.memories.state,
      ),
      isEmpty,
    );
  });
}
