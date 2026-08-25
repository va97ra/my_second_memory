import '../memory/memory_item.dart';
import '../recurrence/recurrence_series.dart';
import '../memory/memory_status.dart';
import '../memory/memory_type.dart';

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
  payment,
  recurringMonthly,
  recurringYearly;

  /// Частота повторов, которые показывает фильтр, или null для обычных
  /// фильтров.
  ///
  /// Повтор случается раз в месяц или раз в год, поэтому такой фильтр
  /// раскрывает ленту на весь свой период: в отдельно взятом дне смотреть было
  /// бы не на что.
  RecurrenceFrequency? get recurringFrequency => switch (this) {
        FeedFilter.recurringMonthly => RecurrenceFrequency.monthly,
        FeedFilter.recurringYearly => RecurrenceFrequency.yearly,
        _ => null,
      };

  /// Вид записи, который отбирает фильтр, или null, если фильтр отбирает не по
  /// виду. Отсюда берут и подпись, и значок: список видов один на всех.
  MemoryType? get memoryType => switch (this) {
        FeedFilter.task => MemoryType.task,
        FeedFilter.note => MemoryType.note,
        FeedFilter.event => MemoryType.event,
        FeedFilter.goal => MemoryType.goal,
        FeedFilter.project => MemoryType.project,
        FeedFilter.purchase => MemoryType.purchase,
        FeedFilter.document => MemoryType.document,
        FeedFilter.place => MemoryType.place,
        FeedFilter.birthday => MemoryType.birthday,
        FeedFilter.payment => MemoryType.payment,
        _ => null,
      };

  /// Фильтры по виду записи — те, что уместны везде, где есть записи.
  static List<FeedFilter> get byMemoryType => [
        for (final filter in FeedFilter.values)
          if (filter.memoryType != null) filter,
      ];
}

List<MemoryItem> smartFeedForDay(List<MemoryItem> items, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);

  final visible = items
      .where((item) =>
          !item.isArchived && !item.isUndated && !isRecurringItem(item))
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
        !item.isUndated &&
        !isRecurringItem(item) &&
        !hiddenFutureOccurrence &&
        matchesFeedFilter(item, filter);
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

/// Повторяющаяся ли это запись.
///
/// Проверяется и по серии, и по правилу повтора: запись, спроецированная из
/// серии, приходит с обоими признаками, а запись, у которой повтор только что
/// сняли, — ни с одним.
/// Частота повтора записи, или null, если запись не повторяется.
RecurrenceFrequency? recurrenceFrequencyOf(MemoryItem item) {
  final repeatRule = item.repeatRule?.trim().toLowerCase();
  for (final frequency in RecurrenceFrequency.values) {
    if (repeatRule == frequency.name) return frequency;
  }
  return null;
}

bool isRecurringItem(MemoryItem item) {
  final repeatRule = item.repeatRule?.trim().toLowerCase();
  return item.seriesId != null ||
      repeatRule == 'monthly' ||
      repeatRule == 'yearly';
}

bool matchesFeedFilter(MemoryItem item, FeedFilter filter) {
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
    FeedFilter.recurringMonthly =>
      recurrenceFrequencyOf(item) == RecurrenceFrequency.monthly,
    FeedFilter.recurringYearly =>
      recurrenceFrequencyOf(item) == RecurrenceFrequency.yearly,
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
