import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/calendar_month_data.dart';
import 'calendar_day_cell.dart';

/// Сетка месяца: семь столбцов и столько строк, сколько занял месяц.
///
/// Ячейки не прокручиваются: месяц целиком помещается в отведённую высоту, а
/// её делят поровну между строками.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    super.key,
    required this.locale,
    required this.visibleMonth,
    required this.selectedDate,
    required this.monthData,
    required this.onSelectDate,
  });

  final String locale;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final CalendarMonthData monthData;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final days = monthData.days;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 2.0;
        final rowCount = days.length ~/ 7;
        final cellWidth = (constraints.maxWidth - spacing * 6) / 7;
        final cellHeight =
            (constraints.maxHeight - spacing * (rowCount - 1)) / rowCount;

        return SizedBox.expand(
          key: const ValueKey('calendar_month_grid'),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: cellWidth / cellHeight,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) => _cell(days[index]),
          ),
        );
      },
    );
  }

  /// Дни соседних месяцев показываются пустыми: их содержимое принадлежит
  /// другой странице календаря.
  Widget _cell(DateTime day) {
    final isInVisibleMonth = day.month == visibleMonth.month;
    final key = dateKey(day);

    return CalendarDayCell(
      key: ValueKey('calendar_day_${calendarDateStringKey(day)}'),
      date: day,
      locale: locale,
      isInVisibleMonth: isInVisibleMonth,
      isSelected: isSameDay(day, selectedDate),
      isToday: isSameDay(day, DateTime.now()),
      items: isInVisibleMonth
          ? monthData.itemsByDay[key] ?? const <MemoryItem>[]
          : const <MemoryItem>[],
      shiftSchedules: isInVisibleMonth
          ? monthData.shiftsByDay[key] ?? const <ShiftSchedule>[]
          : const <ShiftSchedule>[],
      holidays: isInVisibleMonth
          ? monthData.holidaysByDay[key] ?? const <HolidayOccurrence>[]
          : const <HolidayOccurrence>[],
      hasAlarm: isInVisibleMonth && monthData.alarmDays.contains(key),
      onTap: () => onSelectDate(day),
    );
  }
}
