import 'package:flutter_test/flutter_test.dart';
import 'package:ez_domain/ez_domain.dart';

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

  test('returns immediately when there are no enabled series', () {
    final disabled = series(
      RecurrenceFrequency.monthly,
      DateTime(2026, 1, 20),
    ).copyWith(isEnabled: false);

    final result = const RecurrenceProjectionService().itemsForRange(
      start: DateTime(2026, 2),
      end: DateTime(2026, 2, 28),
      series: [disabled],
      exceptions: const [],
      persistedItems: const [],
    );

    expect(result, isEmpty);
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

  test('source skip suppresses a stale miskeyed modified marker', () {
    final entry = series(RecurrenceFrequency.monthly, DateTime(2026, 1, 20));
    final sourceDate = DateTime(2026, 2, 20);
    final movedDate = DateTime(2026, 2, 22);
    final staleMoved = occurrenceFromSeries(entry, sourceDate).copyWith(
      memoryDate: movedDate,
      body: 'Устаревшая правка из облака',
    );
    final deletionTime = DateTime(2026, 2, 21, 12);
    final result = const RecurrenceProjectionService().itemsForRange(
      start: DateTime(2026, 2),
      end: DateTime(2026, 2, 28),
      series: [entry],
      exceptions: [
        RecurrenceOccurrenceException(
          id: recurrenceExceptionId(entry.id, sourceDate),
          seriesId: entry.id,
          occurrenceDate: sourceDate,
          kind: RecurrenceOccurrenceExceptionKind.skipped,
          createdAt: deletionTime,
          updatedAt: deletionTime,
        ),
        RecurrenceOccurrenceException(
          id: recurrenceExceptionId(entry.id, movedDate),
          seriesId: entry.id,
          occurrenceDate: movedDate,
          kind: RecurrenceOccurrenceExceptionKind.modified,
          item: staleMoved,
          createdAt: sourceDate,
          updatedAt: sourceDate,
        ),
      ],
      persistedItems: const [],
    );

    expect(result, isEmpty);
  });

  test('occurrence index suppresses persisted item at a skipped source date',
      () {
    final entry = series(RecurrenceFrequency.monthly, DateTime(2026, 1, 20));
    final sourceDate = DateTime(2026, 2, 20);
    final persisted = occurrenceFromSeries(entry, sourceDate);
    final deletionTime = DateTime(2026, 2, 21, 12);
    final index = RecurrenceOccurrenceIndex(
      series: [entry],
      exceptions: [
        RecurrenceOccurrenceException(
          id: recurrenceExceptionId(entry.id, sourceDate),
          seriesId: entry.id,
          occurrenceDate: sourceDate,
          kind: RecurrenceOccurrenceExceptionKind.skipped,
          createdAt: deletionTime,
          updatedAt: deletionTime,
        ),
      ],
    );

    expect(index.sourceDateFor(persisted), sourceDate);
    expect(index.isSkippedPersisted(persisted), isTrue);
  });

  test('legacy source skip does not suppress a moved persisted item', () {
    final entry = series(RecurrenceFrequency.monthly, DateTime(2026, 1, 20));
    final sourceDate = DateTime(2026, 2, 20);
    final movedDate = DateTime(2026, 2, 22);
    final moved = occurrenceFromSeries(entry, sourceDate).copyWith(
      memoryDate: movedDate,
    );
    final index = RecurrenceOccurrenceIndex(
      series: [entry],
      exceptions: [
        RecurrenceOccurrenceException(
          id: recurrenceExceptionId(entry.id, sourceDate),
          seriesId: entry.id,
          occurrenceDate: sourceDate,
          kind: RecurrenceOccurrenceExceptionKind.skipped,
          createdAt: movedDate,
          updatedAt: movedDate,
        ),
      ],
    );

    expect(index.sourceDateFor(moved), sourceDate);
    expect(index.isSkippedPersisted(moved), isFalse);
  });

  test('itemById does not return a persisted item hidden by a source skip', () {
    final entry = series(RecurrenceFrequency.monthly, DateTime(2026, 1, 20));
    final sourceDate = DateTime(2026, 2, 20);
    final persisted = occurrenceFromSeries(entry, sourceDate);
    final deletionTime = DateTime(2026, 2, 21, 12);

    final result = const RecurrenceProjectionService().itemById(
      id: persisted.id,
      series: [entry],
      exceptions: [
        RecurrenceOccurrenceException(
          id: recurrenceExceptionId(entry.id, sourceDate),
          seriesId: entry.id,
          occurrenceDate: sourceDate,
          kind: RecurrenceOccurrenceExceptionKind.skipped,
          createdAt: deletionTime,
          updatedAt: deletionTime,
        ),
      ],
      persistedItems: [persisted],
    );

    expect(result, isNull);
  });
}
