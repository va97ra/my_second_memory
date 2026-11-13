import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/provider_test_support.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_providers.dart';

void main() {
  test('repeated "this and future" saves never build a chain of series',
      () async {
    final start = DateTime(2026, 1, 9);
    final origin = MemoryItem(
      id: 'origin',
      type: MemoryType.birthday,
      title: 'Анаста',
      body: 'Анаста',
      memoryDate: start,
      createdAt: start,
      updatedAt: start,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: origin,
      startDate: start,
      originItemId: origin.id,
      createdAt: start,
      updatedAt: start,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': jsonEncode([origin.toJson()]),
      LocalRecurrenceRepository.storageKey: jsonEncode([series.toJson()]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });

    final container = testContainer();
    final memories = container.read(memoryItemsControllerProvider.notifier);
    final exceptions =
        container.read(recurrenceExceptionControllerProvider.notifier);
    final controller =
        container.read(recurrenceSeriesControllerProvider.notifier);
    await controller.load();

    // Autosave fires once per pause in typing, all with the same scope.
    var current = controller.state.single.template;
    for (final name in ['Анастас', 'Анастаси', 'Анастасия Железникова']) {
      final saved = await controller.applyToFuture(
        current.copyWith(title: name, body: name),
        occurrenceDate: start,
      );
      expect(saved, isNotNull);
      current = controller.state.single.template;
    }
    expect(memories.state, isEmpty,
        reason: 'a recurring record lives in its series, not in a row');

    expect(controller.state, hasLength(1),
        reason: 'six autosaves must still leave exactly one series');
    expect(controller.state.single.template.title, 'Анастасия Железникова');
    expect(controller.state.single.id.length, lessThan(40),
        reason: 'the series id must not grow with every save');
    expect(
      const RecurrenceProjectionService()
          .itemsForRange(
            start: start,
            end: DateTime(2029, 1, 9),
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          .map((item) => item.title)
          .toSet(),
      {'Анастасия Железникова'},
      reason: 'every projected occurrence uses the edited template',
    );
  });
}
