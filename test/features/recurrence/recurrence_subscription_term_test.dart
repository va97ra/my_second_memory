import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recurrence_test_support.dart';

void main() {
  test('subscription term limits monthly occurrences and can be cleared',
      () async {
    final createdAt = DateTime(2025, 1, 1);
    final payment = MemoryItem(
      id: 'subscription-origin',
      type: MemoryType.payment,
      title: 'Подписка',
      memoryDate: DateTime(2099, 1, 31),
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'subscription-series',
      repeatRule: RecurrenceFrequency.monthly.name,
      amountMinor: 49900,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final series = RecurrenceSeries(
      id: 'subscription-series',
      frequency: RecurrenceFrequency.monthly,
      template: payment,
      startDate: payment.memoryDate,
      originItemId: payment.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([payment]),
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

    final threeMonths =
        await controller.setTermMonths('subscription-series', 3);
    expect(threeMonths?.subscriptionEndDate, DateTime(2099, 3, 31));
    expect(threeMonths?.endDate, isNull);
    expect(
      recurrenceDatesInRange(
        threeMonths!,
        DateTime(2099),
        DateTime(2101),
      ),
      [
        DateTime(2099, 1, 31),
        DateTime(2099, 2, 28),
        DateTime(2099, 3, 31),
      ],
    );

    final fourteenMonths =
        await controller.setTermMonths('subscription-series', 14);
    expect(fourteenMonths?.subscriptionEndDate, DateTime(2100, 2, 28));
    expect(
      recurrenceDatesInRange(
        fourteenMonths!,
        DateTime(2099),
        DateTime(2101),
      ),
      hasLength(14),
    );

    final unlimited =
        await controller.setTermMonths('subscription-series', null);
    expect(unlimited?.subscriptionEndDate, isNull);
    expect(
      recurrenceDatesInRange(
        unlimited!,
        DateTime(2099),
        DateTime(2101),
      ).length,
      greaterThan(14),
    );
  });

  test('clearing a subscription term preserves a deletion cutoff', () async {
    final createdAt = DateTime(2025, 1, 1);
    final payment = MemoryItem(
      id: 'subscription-origin',
      type: MemoryType.payment,
      title: 'Подписка',
      memoryDate: DateTime(2099, 1, 15),
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'subscription-series',
      repeatRule: RecurrenceFrequency.monthly.name,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final deletionCutoff = DateTime(2099, 5, 14);
    final series = RecurrenceSeries(
      id: 'subscription-series',
      frequency: RecurrenceFrequency.monthly,
      template: payment,
      startDate: payment.memoryDate,
      originItemId: payment.id,
      createdAt: createdAt,
      updatedAt: createdAt,
      endDate: deletionCutoff,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([payment]),
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

    await controller.setTermMonths('subscription-series', 3);
    final cleared = await controller.setTermMonths('subscription-series', null);

    expect(cleared?.subscriptionEndDate, isNull);
    expect(cleared?.endDate, deletionCutoff);
    expect(
      recurrenceDatesInRange(cleared!, DateTime(2099), DateTime(2100)),
      [
        DateTime(2099, 1, 15),
        DateTime(2099, 2, 15),
        DateTime(2099, 3, 15),
        DateTime(2099, 4, 15),
      ],
    );
  });

  test('splitting a subscription keeps its existing absolute end date',
      () async {
    final createdAt = DateTime(2025, 1, 1);
    final payment = MemoryItem(
      id: 'subscription-origin',
      type: MemoryType.payment,
      title: 'Подписка',
      memoryDate: DateTime(2099, 1, 15),
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'subscription-series',
      repeatRule: RecurrenceFrequency.monthly.name,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final series = RecurrenceSeries(
      id: 'subscription-series',
      frequency: RecurrenceFrequency.monthly,
      template: payment,
      startDate: payment.memoryDate,
      originItemId: payment.id,
      createdAt: createdAt,
      updatedAt: createdAt,
      subscriptionEndDate: DateTime(2099, 12, 15),
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([payment]),
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

    final june = DateTime(2099, 6, 15);
    final edited = occurrenceFromSeries(controller.state.single, june);
    final replacement = await controller.applyToFuture(
      edited,
      occurrenceDate: june,
    );
    final unchangedTerm = await controller.setTermMonths(replacement!.id, 7);

    expect(unchangedTerm?.startDate, june);
    expect(unchangedTerm?.subscriptionEndDate, DateTime(2099, 12, 15));
    expect(
      recurrenceDatesInRange(
        unchangedTerm!,
        june,
        DateTime(2100, 1, 1),
      ),
      [
        DateTime(2099, 6, 15),
        DateTime(2099, 7, 15),
        DateTime(2099, 8, 15),
        DateTime(2099, 9, 15),
        DateTime(2099, 10, 15),
        DateTime(2099, 11, 15),
        DateTime(2099, 12, 15),
      ],
    );
  });
}
