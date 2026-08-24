import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

MemoryItem _record({
  String id = 'origin',
  MemoryType type = MemoryType.payment,
  String? paymentCategory,
  DateTime? memoryDate,
  String seriesId = 'series',
}) {
  final date = memoryDate ?? DateTime(2026, 3, 10);
  return MemoryItem(
    id: id,
    type: type,
    title: 'Интернет',
    body: 'Интернет',
    memoryDate: date,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: date,
    seriesId: seriesId,
    repeatRule: RecurrenceFrequency.monthly.name,
    paymentCategory: paymentCategory,
    amountMinor: 99900,
  );
}

RecurrenceSeries _series({
  DateTime? startDate,
  DateTime? subscriptionEndDate,
  MemoryItem? template,
}) {
  final start = startDate ?? DateTime(2026, 3, 10);
  return RecurrenceSeries(
    id: 'series',
    frequency: RecurrenceFrequency.monthly,
    template: template ?? _record(memoryDate: start),
    startDate: start,
    originItemId: 'origin',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    subscriptionEndDate: subscriptionEndDate,
  );
}

void main() {
  test('editing the first occurrence changes the series in place', () {
    final current = _series();

    final split = splitSeriesForFutureEdit(
      current: current,
      edited: _record().copyWith(amountMinor: 120000),
      cutoff: DateTime(2026, 3, 10),
      now: DateTime(2026, 3, 10, 12),
    );

    // Автосохранение повторяет ту же правку на каждой паузе в наборе. Если бы
    // она делила серию, одна запись обзавелась бы цепочкой серий.
    expect(split.splits, isFalse);
    expect(split.replacement.id, current.id);
    expect(split.replacement.template.amountMinor, 120000);
  });

  test('editing a later occurrence ends the old series a day before', () {
    final current = _series();
    final june = _record(id: 'series_20260610', memoryDate: DateTime(2026, 6, 10));

    final split = splitSeriesForFutureEdit(
      current: current,
      edited: june.copyWith(amountMinor: 150000),
      cutoff: DateTime(2026, 6, 10),
      now: DateTime(2026, 6, 10, 12),
    );

    expect(split.splits, isTrue);
    expect(split.ended!.endDate, DateTime(2026, 6, 9));
    expect(split.replacement.startDate, DateTime(2026, 6, 10));
    expect(split.replacement.id, isNot(current.id));
    expect(split.replacement.template.amountMinor, 150000);
    expect(split.replacement.originItemId, split.replacement.template.id);
  });

  test('a moved occurrence cuts on its source date and starts on the new one',
      () {
    final current = _series();
    // Вхождение июня перенесли на 15-е: адресуется оно по 10-му.
    final moved = _record(
      id: 'series_20260610',
      memoryDate: DateTime(2026, 6, 15),
    );

    final split = splitSeriesForFutureEdit(
      current: current,
      edited: moved,
      cutoff: DateTime(2026, 6, 10),
      now: DateTime(2026, 6, 15, 12),
    );

    expect(split.ended!.endDate, DateTime(2026, 6, 9));
    expect(split.replacement.startDate, DateTime(2026, 6, 15));
  });

  test('the subscription term follows only a monthly payment subscription',
      () {
    final term = DateTime(2026, 9, 10);
    final subscription = _series(
      subscriptionEndDate: term,
      template: _record(paymentCategory: PaymentCategory.subscription.name),
    );

    final kept = splitSeriesForFutureEdit(
      current: subscription,
      edited: _record(
        id: 'series_20260610',
        memoryDate: DateTime(2026, 6, 10),
        paymentCategory: PaymentCategory.subscription.name,
      ),
      cutoff: DateTime(2026, 6, 10),
      now: DateTime(2026, 6, 10, 12),
    );
    expect(kept.replacement.subscriptionEndDate, term);

    // Стала обычной квартплатой — срок подписки больше не о чём.
    final dropped = splitSeriesForFutureEdit(
      current: subscription,
      edited: _record(
        id: 'series_20260610',
        memoryDate: DateTime(2026, 6, 10),
        paymentCategory: PaymentCategory.utilities.name,
      ),
      cutoff: DateTime(2026, 6, 10),
      now: DateTime(2026, 6, 10, 12),
    );
    expect(dropped.replacement.subscriptionEndDate, isNull);
  });

  test('setting the repeat twice keeps one series, not two', () {
    final record = _record(paymentCategory: PaymentCategory.subscription.name);
    final first = RecurrenceSeries.forRecord(
      record: record.copyWith(clearSeries: true),
      frequency: RecurrenceFrequency.monthly,
      now: DateTime(2026, 3, 10, 12),
    );

    // Та же запись, настроенная повторно: серия остаётся прежней.
    final again = RecurrenceSeries.forRecord(
      record: record.copyWith(seriesId: first.id, amountMinor: 120000),
      frequency: RecurrenceFrequency.monthly,
      now: DateTime(2026, 3, 11, 12),
      existing: first,
    );

    expect(again.id, first.id);
    expect(again.startDate, first.startDate);
    expect(again.originItemId, first.originItemId);
    expect(again.createdAt, first.createdAt);
    expect(again.template.amountMinor, 120000);
  });

  test('switching a subscription to yearly drops its term', () {
    final monthly = RecurrenceSeries.forRecord(
      record: _record(paymentCategory: PaymentCategory.subscription.name)
          .copyWith(clearSeries: true),
      frequency: RecurrenceFrequency.monthly,
      now: DateTime(2026, 3, 10, 12),
    ).copyWith(subscriptionEndDate: DateTime(2026, 9, 10));

    final yearly = RecurrenceSeries.forRecord(
      record: monthly.template,
      frequency: RecurrenceFrequency.yearly,
      now: DateTime(2026, 3, 11, 12),
      existing: monthly,
    );

    expect(yearly.subscriptionEndDate, isNull);
  });

  test('the term rule is the same one everywhere', () {
    expect(
      keepsSubscriptionTerm(
        type: MemoryType.payment,
        paymentCategory: PaymentCategory.subscription.name,
        frequency: RecurrenceFrequency.monthly,
      ),
      isTrue,
    );
    expect(
      keepsSubscriptionTerm(
        type: MemoryType.payment,
        paymentCategory: PaymentCategory.subscription.name,
        frequency: RecurrenceFrequency.yearly,
      ),
      isFalse,
    );
    expect(
      keepsSubscriptionTerm(
        type: MemoryType.note,
        paymentCategory: PaymentCategory.subscription.name,
        frequency: RecurrenceFrequency.monthly,
      ),
      isFalse,
    );
    expect(
      keepsSubscriptionTerm(
        type: MemoryType.payment,
        paymentCategory: null,
        frequency: RecurrenceFrequency.monthly,
      ),
      isFalse,
    );
  });
}
