import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import 'calendar_preferences_controller.dart';
import '../../memory_items/memory_items.dart';
import '../../shift_schedules/shift_schedules.dart';
import 'holiday_providers.dart';

class CalendarMonthData {
  const CalendarMonthData({
    required this.days,
    required this.itemsByDay,
    required this.shiftsByDay,
    required this.shiftSchedules,
    required this.holidaysByDay,
    required this.alarmDays,
  });

  factory CalendarMonthData.build({
    required DateTime month,
    required List<MemoryItem> items,
    List<MemoryItem> allItems = const [],
    Set<int> persistedAlarmDays = const {},
    required List<ShiftSchedule> shiftSchedules,
    HolidayCalendarService? holidayService,
    bool showHolidays = true,
  }) {
    final resolvedHolidayService = holidayService ?? HolidayCalendarService();
    final days = calendarDaysForMonth(month);
    final itemsByDay = <int, List<MemoryItem>>{};
    for (final item in items) {
      itemsByDay
          .putIfAbsent(dateKey(item.memoryDate), () => [])
          .add(item);
    }
    final shiftsByDay = <int, List<ShiftSchedule>>{};
    for (final day in days) {
      final matches = [
        for (final schedule in shiftSchedules)
          if (schedule.isWorkday(day)) schedule,
      ];
      if (matches.isNotEmpty) shiftsByDay[dateKey(day)] = matches;
    }
    final holidaysByDay = <int, List<HolidayOccurrence>>{};
    if (showHolidays) {
      for (final holiday
          in resolvedHolidayService.holidaysForRange(days.first, days.last)) {
        holidaysByDay
            .putIfAbsent(dateKey(holiday.date), () => [])
            .add(holiday);
      }
    }
    final alarmDays = <int>{...persistedAlarmDays};
    final reminderItems = persistedAlarmDays.isEmpty
        ? <String, MemoryItem>{
            for (final item in allItems) item.id: item,
            for (final item in items) item.id: item,
          }.values
        : items;
    for (final item in reminderItems) {
      if (item.remindAt != null && !item.isDone && !item.isArchived) {
        alarmDays.add(dateKey(item.remindAt!));
      }
    }
    for (final schedule in shiftSchedules) {
      if (!schedule.isEnabled) continue;
      final firstAlarmEnabled =
          schedule.alarms.isNotEmpty && schedule.alarms.first.isEnabled;
      final secondAlarmEnabled = schedule.alarms.length > 1 &&
          schedule.alarms[1].isEnabled &&
          schedule.supportsNextDayAlarm;
      for (final day in days) {
        if (firstAlarmEnabled && schedule.isWorkday(day)) {
          alarmDays.add(dateKey(day));
        }
        if (secondAlarmEnabled &&
            schedule.isWorkday(day.subtract(const Duration(days: 1)))) {
          alarmDays.add(dateKey(day));
        }
      }
    }
    return CalendarMonthData(
      days: days,
      itemsByDay: itemsByDay,
      shiftsByDay: shiftsByDay,
      shiftSchedules: shiftSchedules,
      holidaysByDay: holidaysByDay,
      alarmDays: alarmDays,
    );
  }

  final List<DateTime> days;
  final Map<int, List<MemoryItem>> itemsByDay;
  final Map<int, List<ShiftSchedule>> shiftsByDay;
  final List<ShiftSchedule> shiftSchedules;
  final Map<int, List<HolidayOccurrence>> holidaysByDay;
  final Set<int> alarmDays;
}

final calendarMonthDataProvider =
    Provider.family<CalendarMonthData, DateTime>((ref, month) {
  final memoryIndex = ref.watch(memoryItemsIndexProvider);
  return CalendarMonthData.build(
    month: month,
    items: ref.watch(visibleCalendarItemsProvider(month)),
    persistedAlarmDays: memoryIndex.activeReminderDays,
    shiftSchedules: ref.watch(shiftSchedulesControllerProvider),
    holidayService: ref.watch(holidayCalendarServiceProvider),
    showHolidays: ref.watch(appHolidaysProvider),
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

String calendarDateStringKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
