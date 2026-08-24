import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_item_selectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 5, 12);

  MemoryItem occurrence(String id, {required MemoryStatus status}) {
    return MemoryItem(
      id: id,
      type: MemoryType.payment,
      title: 'Интернет',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      status: status,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.monthly.name,
      isGeneratedOccurrence: true,
    );
  }

  RecurrenceSeries series({bool isEnabled = true}) => RecurrenceSeries(
        id: 'series',
        frequency: RecurrenceFrequency.monthly,
        template: occurrence('origin', status: MemoryStatus.active),
        startDate: date,
        originItemId: 'origin',
        isEnabled: isEnabled,
        createdAt: date,
        updatedAt: date,
      );

  RecurrenceOccurrenceException marker(
    MemoryItem? item, {
    required RecurrenceOccurrenceExceptionKind kind,
  }) {
    return RecurrenceOccurrenceException(
      id: recurrenceExceptionId('series', date),
      seriesId: 'series',
      occurrenceDate: date,
      kind: kind,
      item: item,
      createdAt: date,
      updatedAt: date,
    );
  }

  test('an archived recurring occurrence reaches the archive', () {
    final archived = archivedMemoryItems(
      rows: const [],
      series: [series()],
      exceptions: [
        marker(
          occurrence('origin', status: MemoryStatus.archived),
          kind: RecurrenceOccurrenceExceptionKind.modified,
        ),
      ],
    );

    expect(archived.map((item) => item.id), ['origin'],
        reason: 'archiving an occurrence writes a marker, not a row');
  });

  test('a deleted occurrence never shows up as archived', () {
    final archived = archivedMemoryItems(
      rows: const [],
      series: [series()],
      exceptions: [
        marker(
          occurrence('origin', status: MemoryStatus.archived),
          kind: RecurrenceOccurrenceExceptionKind.skipped,
        ),
      ],
    );

    expect(archived, isEmpty);
  });

  test('an active occurrence is not archived', () {
    final archived = archivedMemoryItems(
      rows: const [],
      series: [series()],
      exceptions: [
        marker(
          occurrence('origin', status: MemoryStatus.active),
          kind: RecurrenceOccurrenceExceptionKind.modified,
        ),
      ],
    );

    expect(archived, isEmpty);
  });

  test('a switched-off series keeps its occurrences out of the archive', () {
    final archived = archivedMemoryItems(
      rows: const [],
      series: [series(isEnabled: false)],
      exceptions: [
        marker(
          occurrence('origin', status: MemoryStatus.archived),
          kind: RecurrenceOccurrenceExceptionKind.modified,
        ),
      ],
    );

    expect(archived, isEmpty);
  });

  test('plain archived records still come through untouched', () {
    final note = MemoryItem(
      id: 'note',
      type: MemoryType.note,
      title: 'Заметка',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      status: MemoryStatus.archived,
    );

    final archived = archivedMemoryItems(
      rows: [note],
      series: const [],
      exceptions: const [],
    );

    expect(archived.map((item) => item.id), ['note']);
  });
}
