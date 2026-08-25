import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recurrence_test_support.dart';

void main() {
  test('moved origin can be deleted without returning from its marker',
      () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final sourceDate = DateTime(2099, 1, 9);
    final movedDate = DateTime(2099, 2, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Встреча',
      body: 'Встреча',
      memoryDate: sourceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: sourceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([template]),
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });
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
    await controller.saveOccurrenceOverride(
      template.copyWith(memoryDate: movedDate),
      occurrenceDate: sourceDate,
    );
    final moved = exceptions.state.single.item!;
    final duplicateUpdatedAt = moved.updatedAt.add(const Duration(seconds: 1));
    await exceptions.upsert(
      RecurrenceOccurrenceException(
        id: recurrenceExceptionId(series.id, movedDate),
        seriesId: series.id,
        occurrenceDate: movedDate,
        kind: RecurrenceOccurrenceExceptionKind.modified,
        item: moved.copyWith(updatedAt: duplicateUpdatedAt),
        createdAt: moved.updatedAt,
        updatedAt: duplicateUpdatedAt,
      ),
    );

    await controller.deleteOccurrence(moved);

    expect(memories.state, isEmpty);
    expect(exceptions.state, hasLength(1));
    expect(exceptions.state.single.isSkipped, isTrue);
    expect(exceptions.state.single.occurrenceDate, sourceDate);
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

  test('load recovers the newest partial edit of a moved origin', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final sourceDate = DateTime(2099, 1, 9);
    final movedDate = DateTime(2099, 2, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Исходное значение',
      body: 'Исходное значение',
      memoryDate: sourceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final moved = template.copyWith(
      title: 'Первая правка',
      body: 'Первая правка',
      memoryDate: movedDate,
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    final newest = moved.copyWith(
      title: 'Вторая правка',
      body: 'Вторая правка',
      updatedAt: createdAt.add(const Duration(minutes: 2)),
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: sourceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final deletionTime = createdAt.add(const Duration(seconds: 90));
    final olderSkip = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, sourceDate),
      seriesId: series.id,
      occurrenceDate: sourceDate,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      createdAt: deletionTime,
      updatedAt: deletionTime,
    );
    final misplacedNewestMarker = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, movedDate),
      seriesId: series.id,
      occurrenceDate: movedDate,
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: newest,
      createdAt: newest.updatedAt,
      updatedAt: newest.updatedAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([moved]),
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey:
          encodeExceptions([olderSkip, misplacedNewestMarker]),
    });
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

    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Вторая правка',
      reason: 'the record shows the edit, wherever it is stored',
    );
    expect(exceptions.state, hasLength(1));
    expect(exceptions.state.single.occurrenceDate, sourceDate);
    expect(exceptions.state.single.item?.title, 'Вторая правка');
  });

  test('load completes a deletion after its skip was committed first',
      () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final sourceDate = DateTime(2099, 1, 9);
    final movedDate = DateTime(2099, 2, 9);
    final moved = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Удаляемая встреча',
      body: 'Удаляемая встреча',
      memoryDate: movedDate,
      createdAt: createdAt,
      updatedAt: createdAt.add(const Duration(minutes: 1)),
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: moved.copyWith(
        memoryDate: sourceDate,
        updatedAt: createdAt,
      ),
      startDate: sourceDate,
      originItemId: moved.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final deletionTime = createdAt.add(const Duration(minutes: 2));
    final skip = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, sourceDate),
      seriesId: series.id,
      occurrenceDate: sourceDate,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      item: moved,
      createdAt: deletionTime,
      updatedAt: deletionTime,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([moved]),
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey: encodeExceptions([skip]),
    });
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

    expect(memories.state, isEmpty);
    expect((await const LocalMemoryRepository().loadAll()), isEmpty);
    expect(exceptions.state.single.isSkipped, isTrue);
  });
}
