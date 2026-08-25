import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recurrence_test_support.dart';

void main() {
  test('origin override marker prevents metadata edits becoming a template',
      () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.birthday,
      title: 'Анастасия',
      body: 'Анастасия',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: occurrenceDate,
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
      template.copyWith(
        birthYear: 1991,
        updatedAt: createdAt.add(const Duration(minutes: 5)),
      ),
      occurrenceDate: occurrenceDate,
    );

    expect(exceptions.state, hasLength(1));
    expect(exceptions.state.single.item?.id, template.id);
    // Every occurrence, the first one included, is projected from the series.
    expect(exceptions.state.single.item?.isGeneratedOccurrence, isTrue);
    expect(exceptions.state.single.item?.birthYear, 1991);
    expect(memories.state, isEmpty);

    final reloadedMemories =
        MemoryItemsController(const LocalMemoryRepository());
    final reloadedExceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
    );
    final reloadedReminders = NotificationService();
    addTearDown(reloadedReminders.dispose);
    final reloaded = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      reloadedExceptions,
      reloadedMemories,
      reloadedReminders,
    );
    await reloaded.load();

    expect(reloaded.state.single.template.birthYear, isNull);
    expect(reloadedExceptions.state.single.item?.birthYear, 1991);
    expect(reloadedExceptions.state, hasLength(1));
  });

  test('load restores a newer origin override after a partial write', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Старое значение',
      body: 'Старое значение',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: occurrenceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final overrideItem = template.copyWith(
      title: 'Новое значение',
      body: 'Новое значение',
      updatedAt: createdAt.add(const Duration(seconds: 5)),
    );
    final exception = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, occurrenceDate),
      seriesId: series.id,
      occurrenceDate: occurrenceDate,
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: overrideItem,
      createdAt: overrideItem.updatedAt,
      updatedAt: overrideItem.updatedAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([template]),
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey:
          encodeExceptions([exception]),
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

    expect(controller.state.single.template.title, 'Старое значение');
    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Новое значение',
      reason: 'the record shows the edit, wherever it is stored',
    );
    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Новое значение',
    );
    expect(
      (await const LocalRecurrenceExceptionRepository().loadAll())
          .single
          .item
          ?.title,
      'Новое значение',
    );
  });

  test('downloaded origin override is reconciled without a restart', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Локальное значение',
      body: 'Локальное значение',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: occurrenceDate,
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
    final remoteItem = template.copyWith(
      title: 'Значение с другого устройства',
      body: 'Значение с другого устройства',
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    await exceptions.replaceAll([
      RecurrenceOccurrenceException(
        id: recurrenceExceptionId(series.id, occurrenceDate),
        seriesId: series.id,
        occurrenceDate: occurrenceDate,
        kind: RecurrenceOccurrenceExceptionKind.modified,
        item: remoteItem,
        createdAt: remoteItem.updatedAt,
        updatedAt: remoteItem.updatedAt,
      ),
    ]);

    await controller.reconcileOriginOverrides();

    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Значение с другого устройства',
      reason: 'the record shows the edit, wherever it is stored',
    );
  });
}
