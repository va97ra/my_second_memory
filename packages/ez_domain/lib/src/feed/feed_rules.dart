import '../memory/memory_item.dart';
import '../recurrence/recurrence_series.dart';
import '../memory/memory_type.dart';

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

/// Частота повтора записи, или null, если запись не повторяется.
RecurrenceFrequency? recurrenceFrequencyOf(MemoryItem item) {
  final repeatRule = item.repeatRule?.trim().toLowerCase();
  for (final frequency in RecurrenceFrequency.values) {
    if (repeatRule == frequency.name) return frequency;
  }
  return null;
}

bool matchesFeedFilter(MemoryItem item, FeedFilter filter) {
  return switch (filter) {
    FeedFilter.all => true,
    FeedFilter.active => !item.isDone,
    FeedFilter.done => item.isDone,
    FeedFilter.recurringMonthly || FeedFilter.recurringYearly =>
      recurrenceFrequencyOf(item) == filter.recurringFrequency,
    // Остальные фильтры отбирают по виду записи, и какой вид за каким
    // фильтром стоит, знает сам фильтр.
    _ => item.type == filter.memoryType,
  };
}

bool isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
