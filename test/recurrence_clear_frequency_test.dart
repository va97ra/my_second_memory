import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seriesId = 'series';
const _originId = 'origin';

class _Stack {
  _Stack(this.memories, this.exceptions, this.controller);

  final MemoryItemsController memories;
  final RecurrenceExceptionController exceptions;
  final RecurrenceSeriesController controller;

  List<MemoryItem> projected(DateTime start, DateTime end) =>
      const RecurrenceProjectionService().itemsForRange(
        start: start,
        end: end,
        series: controller.state,
        exceptions: exceptions.state,
        persistedItems: memories.state,
      );
}

Future<_Stack> _launch() async {
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
  return _Stack(memories, exceptions, controller);
}

void main() {
  final start = DateTime(2026, 3, 12);

  MemoryItem template() => MemoryItem(
        id: _originId,
        type: MemoryType.payment,
        title: 'Интернет',
        body: 'Интернет',
        timeMinutes: 9 * 60,
        memoryDate: start,
        createdAt: start,
        updatedAt: start,
        amountMinor: 90000,
        paymentCategory: PaymentCategory.subscription.name,
        imagePaths: const ['/photos/receipt.jpg'],
        seriesId: _seriesId,
        repeatRule: RecurrenceFrequency.monthly.name,
      );

  void seed() {
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': '[]',
      LocalRecurrenceRepository.storageKey: jsonEncode([
        RecurrenceSeries(
          id: _seriesId,
          frequency: RecurrenceFrequency.monthly,
          template: template(),
          startDate: start,
          originItemId: _originId,
          createdAt: start,
          updatedAt: start,
        ).toJson(),
      ]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });
  }

  test('removing the repeat gives the record back as a standalone entry',
      () async {
    seed();
    final app = await _launch();
    final first = app.projected(start, start).single;
    expect(first.id, _originId);

    await app.controller.clearFrequency(first);

    expect(app.controller.state, isEmpty, reason: 'the series is gone');
    final restored = app.memories.state.single;
    expect(restored.id, _originId, reason: 'the record keeps its identity');
    expect(restored.title, 'Интернет');
    expect(restored.seriesId, isNull);
    expect(restored.repeatRule, isNull);
    expect(restored.isGeneratedOccurrence, isFalse);
    expect(restored.amountMinor, 90000);
    expect(
      restored.imagePaths,
      ['/photos/receipt.jpg'],
      reason: 'attachments must survive losing the repeat',
    );

    final reloaded = await _launch();
    expect(reloaded.memories.state.single.title, 'Интернет',
        reason: 'and it is still there after a restart');
    expect(reloaded.controller.state, isEmpty);
  });

  test('removing the repeat from a later occurrence keeps one record',
      () async {
    seed();
    final app = await _launch();
    final third = app.projected(
      DateTime(2026, 5, 12),
      DateTime(2026, 5, 12),
    ).single;

    await app.controller.clearFrequency(third);

    expect(app.controller.state, isEmpty);
    expect(
      app.memories.state,
      hasLength(1),
      reason: 'dropping the repeat must not scatter one record into many',
    );
    expect(app.memories.state.single.seriesId, isNull);
    expect(app.memories.state.single.title, 'Интернет');
  });

  test('an edited occurrence does not survive the repeat being removed twice',
      () async {
    seed();
    final app = await _launch();
    await app.controller.saveOccurrenceOverride(
      app.projected(DateTime(2026, 4, 12), DateTime(2026, 4, 12)).single
          .copyWith(title: 'Интернет со скидкой'),
      occurrenceDate: DateTime(2026, 4, 12),
    );
    expect(app.exceptions.state, hasLength(1));

    await app.controller.clearFrequency(
      app.projected(start, start).single,
    );

    expect(app.exceptions.state, isEmpty,
        reason: 'overrides of a series that no longer exists must not linger');
    final reloaded = await _launch();
    expect(reloaded.memories.state, hasLength(1));
    expect(reloaded.controller.state, isEmpty);
    expect(reloaded.exceptions.state, isEmpty);
  });
}
