import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_item_selectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MemoryItem item(String id, DateTime date, {bool isUndated = false}) {
    return MemoryItem(
      id: id,
      type: MemoryType.note,
      title: id,
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      isUndated: isUndated,
    );
  }

  test('indexes dated items once and excludes undated notes', () {
    final firstDate = DateTime(2026, 8, 18, 9);
    final secondDate = DateTime(2026, 8, 19, 14);
    final index = indexMemoryItemsByDate([
      item('first', firstDate),
      item('second', secondDate),
      item('same-day', firstDate.add(const Duration(hours: 3))),
      item('undated', firstDate, isUndated: true),
    ]);

    expect(
      index[memoryItemDateKey(firstDate)]?.map((entry) => entry.id),
      ['first', 'same-day'],
    );
    expect(index[memoryItemDateKey(secondDate)]?.single.id, 'second');
    expect(index.values.expand((items) => items).map((entry) => entry.id),
        isNot(contains('undated')));
    expect(
      () => index[memoryItemDateKey(firstDate)]!.clear(),
      throwsUnsupportedError,
    );
  });
}
