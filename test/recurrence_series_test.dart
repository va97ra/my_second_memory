import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_series.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monthly recurrence uses the last day of short months', () {
    final series = _series(
      frequency: RecurrenceFrequency.monthly,
      start: DateTime(2026, 1, 31),
    );

    final dates = recurrenceDates(series, DateTime(2026, 1, 1));

    expect(dates.take(3), [
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
      DateTime(2026, 4, 30),
    ]);
  });

  test('29 February birthday falls on 28 February in regular years', () {
    final series = _series(
      frequency: RecurrenceFrequency.yearly,
      start: DateTime(2024, 2, 29),
    );

    final dates = recurrenceDates(series, DateTime(2027, 1, 1));

    expect(dates.first, DateTime(2027, 2, 28));
    expect(dates[1], DateTime(2028, 2, 29));
  });

  test('recurrence projection never exceeds two years', () {
    final now = DateTime(2026, 7, 20);
    final monthly = _series(
      frequency: RecurrenceFrequency.monthly,
      start: DateTime(2025, 7, 12),
    );
    final yearly = _series(
      frequency: RecurrenceFrequency.yearly,
      start: DateTime(2020, 8, 1),
    );

    final monthlyDates = recurrenceDates(monthly, now);
    final yearlyDates = recurrenceDates(yearly, now);
    final horizon = recurrenceHorizon(now);

    expect(monthlyDates, hasLength(24));
    expect(monthlyDates.last.isAfter(horizon), isFalse);
    expect(yearlyDates.last.isAfter(horizon), isFalse);
  });

  test('recurrence series preserves its template in json', () {
    final series = _series(
      frequency: RecurrenceFrequency.monthly,
      start: DateTime(2026, 7, 20),
    ).copyWith(generatedThrough: DateTime(2028, 7, 20));

    final restored = RecurrenceSeries.fromJson(series.toJson());

    expect(restored.frequency, RecurrenceFrequency.monthly);
    expect(restored.template.type, MemoryType.payment);
    expect(restored.template.amountMinor, 450000);
    expect(restored.generatedThrough, DateTime(2028, 7, 20));
  });

  test('recurrence can generate only the missing tail', () {
    final series = _series(
      frequency: RecurrenceFrequency.monthly,
      start: DateTime(2026, 7, 20),
    );

    final dates = recurrenceDates(
      series,
      DateTime(2028, 5, 20),
      after: DateTime(2028, 7, 20),
    );

    expect(dates.first, DateTime(2028, 8, 20));
    expect(dates.last, DateTime(2030, 5, 20));
  });
}

RecurrenceSeries _series({
  required RecurrenceFrequency frequency,
  required DateTime start,
}) {
  final item = MemoryItem(
    id: 'origin',
    type: MemoryType.payment,
    title: 'Оплата',
    memoryDate: start,
    createdAt: start,
    updatedAt: start,
    amountMinor: 450000,
  );
  return RecurrenceSeries(
    id: 'series',
    frequency: frequency,
    template: item,
    startDate: start,
    originItemId: item.id,
    createdAt: start,
    updatedAt: start,
  );
}
