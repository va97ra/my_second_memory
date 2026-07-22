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

enum FeedFilter {
  all,
  active,
  done,
  task,
  note,
  event,
  goal,
  project,
  purchase,
  document,
  place,
  birthday,
  payment;
}

List<MemoryItem> smartFeedForDay(List<MemoryItem> items, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);

  final visible = items
      .where((item) => !item.isArchived && !_isRecurringFeedItem(item))
      .toList();

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

List<FeedDay> groupItemsByDate(
  List<MemoryItem> items, {
  FeedFilter filter = FeedFilter.all,
}) {
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  final visible = items.where((item) {
    final hiddenFutureOccurrence = item.isGeneratedOccurrence &&
        DateTime(
          item.memoryDate.year,
          item.memoryDate.month,
          item.memoryDate.day,
        ).isAfter(day);
    return !item.isArchived &&
        !_isRecurringFeedItem(item) &&
        !hiddenFutureOccurrence &&
        _matchesFilter(item, filter);
  }).toList()
    ..sort((a, b) {
      final byDate = b.memoryDate.compareTo(a.memoryDate);
      if (byDate != 0) {
        return byDate;
      }
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      final byVisibleTime = _visibleTimeMinutes(a).compareTo(
        _visibleTimeMinutes(b),
      );
      if (byVisibleTime != 0) {
        return byVisibleTime;
      }
      return a.createdAt.compareTo(b.createdAt);
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

bool _isRecurringFeedItem(MemoryItem item) {
  final repeatRule = item.repeatRule?.trim().toLowerCase();
  return item.seriesId != null ||
      repeatRule == 'monthly' ||
      repeatRule == 'yearly';
}

bool _matchesFilter(MemoryItem item, FeedFilter filter) {
  return switch (filter) {
    FeedFilter.all => true,
    FeedFilter.active => !item.isDone,
    FeedFilter.done => item.isDone,
    FeedFilter.task => item.type == MemoryType.task,
    FeedFilter.note => item.type == MemoryType.note,
    FeedFilter.event => item.type == MemoryType.event,
    FeedFilter.goal => item.type == MemoryType.goal,
    FeedFilter.project => item.type == MemoryType.project,
    FeedFilter.purchase => item.type == MemoryType.purchase,
    FeedFilter.document => item.type == MemoryType.document,
    FeedFilter.place => item.type == MemoryType.place,
    FeedFilter.birthday => item.type == MemoryType.birthday,
    FeedFilter.payment => item.type == MemoryType.payment,
  };
}

int _visibleTimeMinutes(MemoryItem item) {
  return item.timeMinutes ?? item.createdAt.hour * 60 + item.createdAt.minute;
}

bool isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
