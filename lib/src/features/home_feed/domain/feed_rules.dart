import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_status.dart';
import '../../memory_items/domain/memory_type.dart';

class FeedDay {
  const FeedDay({
    required this.date,
    required this.items,
  });

  final DateTime date;
  final List<MemoryItem> items;
}

List<MemoryItem> smartFeedForDay(List<MemoryItem> items, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);

  final visible = items.where((item) => !item.isArchived).toList();

  final dated = visible.where((item) => isSameDay(item.memoryDate, day));
  final overdue = visible.where((item) {
    final itemDay = DateTime(
      item.memoryDate.year,
      item.memoryDate.month,
      item.memoryDate.day,
    );
    return item.type == MemoryType.task &&
        item.status != MemoryStatus.done &&
        itemDay.isBefore(day);
  });

  final feed = [...overdue, ...dated];
  feed.sort((a, b) {
    final priority = b.priority.compareTo(a.priority);
    if (priority != 0) {
      return priority;
    }
    return a.memoryDate.compareTo(b.memoryDate);
  });
  return feed;
}

List<FeedDay> groupItemsByDate(List<MemoryItem> items) {
  final visible = items.where((item) => !item.isArchived).toList()
    ..sort((a, b) {
      final byDate = b.memoryDate.compareTo(a.memoryDate);
      if (byDate != 0) {
        return byDate;
      }
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

  final grouped = <DateTime, List<MemoryItem>>{};
  for (final item in visible) {
    final key = DateTime(
      item.memoryDate.year,
      item.memoryDate.month,
      item.memoryDate.day,
    );
    grouped.putIfAbsent(key, () => []).add(item);
  }

  return grouped.entries
      .map((entry) => FeedDay(date: entry.key, items: entry.value))
      .toList();
}

bool isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
