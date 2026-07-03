import 'package:flutter_test/flutter_test.dart';
import 'package:my_second_memory/src/features/home_feed/domain/feed_rules.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_item.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_status.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_type.dart';

void main() {
  test('smart feed includes today and overdue tasks', () {
    final today = DateTime(2026, 6, 30);
    final yesterday = DateTime(2026, 6, 29);
    final tomorrow = DateTime(2026, 7, 1);

    final items = [
      _item('1', MemoryType.task, yesterday, 'overdue'),
      _item('2', MemoryType.note, today, 'today note'),
      _item('3', MemoryType.event, tomorrow, 'future event'),
    ];

    final feed = smartFeedForDay(items, today);

    expect(feed.map((item) => item.id), ['1', '2']);
  });

  test('groupItemsByDate groups active records by memoryDate', () {
    final items = [
      _item('1', MemoryType.note, DateTime(2026, 6, 30), 'a'),
      _item('2', MemoryType.voiceNote, DateTime(2026, 6, 30), 'b'),
      _item('3', MemoryType.project, DateTime(2026, 7, 1), 'c'),
      _item(
        '4',
        MemoryType.note,
        DateTime(2026, 7, 2),
        'archived',
        status: MemoryStatus.archived,
      ),
    ];

    final groups = groupItemsByDate(items);

    expect(groups.length, 2);
    expect(groups.first.date, DateTime(2026, 7, 1));
    expect(groups.last.items.length, 2);
  });
}

MemoryItem _item(
  String id,
  MemoryType type,
  DateTime date,
  String title, {
  MemoryStatus status = MemoryStatus.active,
}) {
  return MemoryItem(
    id: id,
    type: type,
    title: title,
    memoryDate: date,
    createdAt: date,
    updatedAt: date,
    status: status,
  );
}
