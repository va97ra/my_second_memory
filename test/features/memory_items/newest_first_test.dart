import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_item_selectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MemoryItem item(
    String id, {
    DateTime? date,
    DateTime? updated,
    bool undated = false,
    MemoryStatus status = MemoryStatus.active,
  }) {
    final day = date ?? DateTime(2026, 11, 9);
    return MemoryItem(
      id: id,
      type: MemoryType.note,
      title: id,
      memoryDate: day,
      createdAt: DateTime(2026),
      updatedAt: updated ?? DateTime(2026),
      isUndated: undated,
      status: status,
    );
  }

  test('в архиве чем позже день, тем выше', () {
    final archived = archivedMemoryItems(
      rows: [
        item('old', date: DateTime(2025), status: MemoryStatus.archived),
        item('next', date: DateTime(2027), status: MemoryStatus.archived),
        item('now', date: DateTime(2026), status: MemoryStatus.archived),
      ],
      series: const [],
      exceptions: const [],
    );

    expect(archived.map((i) => i.id), ['next', 'now', 'old']);
  });

  test('в записках сверху та, что менялась последней', () {
    final index = MemoryItemsIndex.build([
      item('old', undated: true, updated: DateTime(2025)),
      item('fresh', undated: true, updated: DateTime(2027)),
      item('middle', undated: true, updated: DateTime(2026)),
    ]);

    expect(index.undatedNotes.map((i) => i.id), ['fresh', 'middle', 'old']);
  });
}
