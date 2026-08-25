import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recurrence_test_support.dart';

void main() {
  test('load repairs a legacy name completed by prepending text', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final completedAt = createdAt.add(const Duration(seconds: 5));
    final occurrenceDate = DateTime(2099, 1, 9);
    final origin = MemoryItem(
      id: 'anastasia-origin',
      type: MemoryType.birthday,
      title: 'Железнякова Анастасия',
      body: 'Железнякова Анастасия',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: completedAt,
      seriesId: 'anastasia-series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final staleTemplate = origin.copyWith(
      title: 'Анаста',
      body: 'Анаста',
      updatedAt: createdAt,
    );
    final series = RecurrenceSeries(
      id: 'anastasia-series',
      frequency: RecurrenceFrequency.yearly,
      template: staleTemplate,
      startDate: occurrenceDate,
      originItemId: origin.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([origin]),
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

    expect(controller.state.single.template.title, 'Железнякова Анастасия');
    expect(controller.state.single.template.body, 'Железнякова Анастасия');
  });

  test('load does not promote text appended to only the origin occurrence',
      () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Купить',
      body: 'Купить',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final editedOrigin = template.copyWith(
      title: 'Купить молоко',
      body: 'Купить молоко',
      updatedAt: createdAt.add(const Duration(seconds: 5)),
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
      'memory_items_v1': encodeItems([editedOrigin]),
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

    expect(controller.state.single.template.title, 'Купить');
    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Купить молоко',
      reason: 'the record shows the edit, wherever it is stored',
    );
  });

  test('load does not promote an interior word fragment', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'дом',
      body: 'дом',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final editedOrigin = template.copyWith(
      title: 'уведомление',
      body: 'уведомление',
      updatedAt: createdAt.add(const Duration(seconds: 5)),
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
      'memory_items_v1': encodeItems([editedOrigin]),
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

    expect(controller.state.single.template.title, 'дом');
    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'уведомление',
      reason: 'the record shows the edit, wherever it is stored',
    );
  });
}
