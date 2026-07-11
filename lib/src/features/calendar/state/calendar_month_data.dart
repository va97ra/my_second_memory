import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_item_selectors.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';

class CalendarMonthData {
  const CalendarMonthData({
    required this.days,
    required this.itemsByDay,
    required this.shiftsByDay,
    required this.shiftSchedules,
  });

  factory CalendarMonthData.build({
    required DateTime month,
    required List<MemoryItem> items,
    required List<ShiftSchedule> shiftSchedules,
  }) {
    final days = calendarDaysForMonth(month);
    final itemsByDay = <int, List<MemoryItem>>{};
    for (final item in items) {
      itemsByDay
          .putIfAbsent(calendarDateKey(item.memoryDate), () => [])
          .add(item);
    }
    final shiftsByDay = <int, List<ShiftSchedule>>{};
    for (final day in days) {
      final matches = [
        for (final schedule in shiftSchedules)
          if (schedule.isWorkday(day)) schedule,
      ];
      if (matches.isNotEmpty) shiftsByDay[calendarDateKey(day)] = matches;
    }
    return CalendarMonthData(
      days: days,
      itemsByDay: itemsByDay,
      shiftsByDay: shiftsByDay,
      shiftSchedules: shiftSchedules,
    );
  }

  final List<DateTime> days;
  final Map<int, List<MemoryItem>> itemsByDay;
  final Map<int, List<ShiftSchedule>> shiftsByDay;
  final List<ShiftSchedule> shiftSchedules;
}

final calendarMonthDataProvider =
    Provider.family<CalendarMonthData, DateTime>((ref, month) {
  return CalendarMonthData.build(
    month: month,
    items: ref.watch(visibleCalendarItemsProvider(month)),
    shiftSchedules: ref.watch(shiftSchedulesControllerProvider),
  );
});

List<DateTime> calendarDaysForMonth(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final leadingDays = firstDay.weekday - DateTime.monday;
  final start = firstDay.subtract(Duration(days: leadingDays));
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
  return [
    for (var index = 0; index < cellCount; index++)
      DateTime(start.year, start.month, start.day + index),
  ];
}

List<String> calendarWeekdayLabels(String locale) => locale == 'ru'
    ? const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
    : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

int calendarDateKey(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

String calendarDateStringKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
