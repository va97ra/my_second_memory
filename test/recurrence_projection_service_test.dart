import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_occurrence_exception.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_projection_service.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_series.dart';

void main() {
  MemoryItem template(DateTime date) => MemoryItem(
        id: 'origin',
        type: MemoryType.note,
        title: 'Повтор',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      );

  RecurrenceSeries series(
    RecurrenceFrequency frequency,
    DateTime date,
  ) =>
      RecurrenceSeries(
        id: 'series',
        frequency: frequency,
        template: template(date),
        startDate: date,
        originItemId: 'origin',
        createdAt: date,
        updatedAt: date,
      );

  test('monthly projection uses the last day of short months', () {
    final result = const RecurrenceProjectionService().itemsForRange(
      start: DateTime(2027, 2),
      end: DateTime(2027, 2, 28),
      series: [series(RecurrenceFrequency.monthly, DateTime(2026, 1, 31))],
      exceptions: const [],
      persistedItems: const [],
    );

    expect(result.single.memoryDate, DateTime(2027, 2, 28));
  });

  test('yearly projection moves February 29 to February 28', () {
    final result = const RecurrenceProjectionService().itemsForRange(
      start: DateTime(2027),
      end: DateTime(2027, 12, 31),
      series: [series(RecurrenceFrequency.yearly, DateTime(2024, 2, 29))],
      exceptions: const [],
      persistedItems: const [],
    );

    expect(result.single.memoryDate, DateTime(2027, 2, 28));
  });

  test('skipped date is hidden and modified date replaces projection', () {
    final entry = series(RecurrenceFrequency.monthly, DateTime(2026, 1, 20));
    final skippedDate = DateTime(2026, 2, 20);
    final modifiedDate = DateTime(2026, 3, 20);
    final modified = occurrenceFromSeries(entry, modifiedDate).copyWith(
      body: 'Изменено',
    );
    final result = const RecurrenceProjectionService().itemsForRange(
      start: DateTime(2026, 2),
      end: DateTime(2026, 3, 31),
      series: [entry],
      exceptions: [
        RecurrenceOccurrenceException(
          id: recurrenceExceptionId(entry.id, skippedDate),
          seriesId: entry.id,
          occurrenceDate: skippedDate,
          kind: RecurrenceOccurrenceExceptionKind.skipped,
          createdAt: skippedDate,
          updatedAt: skippedDate,
        ),
        RecurrenceOccurrenceException(
          id: recurrenceExceptionId(entry.id, modifiedDate),
          seriesId: entry.id,
          occurrenceDate: modifiedDate,
          kind: RecurrenceOccurrenceExceptionKind.modified,
          item: modified,
          createdAt: modifiedDate,
          updatedAt: modifiedDate,
        ),
      ],
      persistedItems: const [],
    );

    expect(result, hasLength(1));
    expect(result.single.body, 'Изменено');
  });

  test('persisted occurrence suppresses the virtual duplicate', () {
    final entry = series(RecurrenceFrequency.monthly, DateTime(2026, 1, 20));
    final date = DateTime(2026, 2, 20);
    final persisted = occurrenceFromSeries(entry, date);

    final result = const RecurrenceProjectionService().itemsForRange(
      start: date,
      end: date,
      series: [entry],
      exceptions: const [],
      persistedItems: [persisted],
    );

    expect(result, isEmpty);
  });

  test('modified occurrence can move to another date', () {
    final entry = series(RecurrenceFrequency.monthly, DateTime(2026, 1, 20));
    final sourceDate = DateTime(2026, 2, 20);
    final targetDate = DateTime(2026, 2, 22);
    final moved = occurrenceFromSeries(entry, sourceDate).copyWith(
      memoryDate: targetDate,
    );
    final exception = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(entry.id, sourceDate),
      seriesId: entry.id,
      occurrenceDate: sourceDate,
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: moved,
      createdAt: sourceDate,
      updatedAt: sourceDate,
    );

    final result = const RecurrenceProjectionService().itemsForRange(
      start: DateTime(2026, 2),
      end: DateTime(2026, 2, 28),
      series: [entry],
      exceptions: [exception],
      persistedItems: const [],
    );

    expect(result.single.memoryDate, targetDate);
  });
}
