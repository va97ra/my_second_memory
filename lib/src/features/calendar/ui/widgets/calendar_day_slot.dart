import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/calendar_month_data.dart';
import '../../state/calendar_today_provider.dart';
import 'calendar_day_cell.dart';

/// Место дня в сетке. Подписано только на данные своего дня: правка записи
/// перерисовывает одну ячейку, а не весь месяц. Дни соседних месяцев показываются
/// пустыми: их данные живут на другой странице календаря.
class CalendarDaySlot extends ConsumerWidget {
  const CalendarDaySlot({
    super.key,
    required this.day,
    required this.locale,
    required this.visibleMonth,
    required this.onTap,
  });

  final DateTime day;
  final String locale;
  final DateTime visibleMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInVisibleMonth = day.month == visibleMonth.month;
    final data = isInVisibleMonth
        ? ref.watch(
            calendarMonthDataProvider(visibleMonth)
                .select((month) => month.cellFor(day)),
          )
        : const CalendarDayCellData();

    return CalendarDayCell(
      date: day,
      locale: locale,
      isInVisibleMonth: isInVisibleMonth,
      // Сегодня берётся у часов календаря: после полуночи отметка переезжает
      // сама, не дожидаясь перерисовки месяца.
      isToday: isSameDay(day, ref.watch(calendarTodayProvider)),
      items: data.items,
      shiftSchedules: data.shifts,
      holidays: data.holidays,
      hasAlarm: data.hasAlarm,
      onTap: onTap,
    );
  }
}
