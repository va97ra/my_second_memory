import 'package:ez_domain/ez_domain.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.onSelectDate,
  });

  final String locale;
  final DateTime visibleMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final days = calendarDaysForMonth(visibleMonth);

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = calendarGridSpacing;
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

  Widget _cell(DateTime day) {
    return _CalendarDaySlot(
      key: ValueKey('calendar_day_${calendarDateStringKey(day)}'),
      day: day,
      locale: locale,
      visibleMonth: visibleMonth,
      onTap: () => onSelectDate(day),
    );
  }
}

/// Место дня в сетке. Подписано только на данные своего дня: правка записи
/// перерисовывает одну ячейку, а не весь месяц. Дни соседних месяцев показываются
/// пустыми: их данные живут на другой странице календаря.
class _CalendarDaySlot extends ConsumerWidget {
  const _CalendarDaySlot({
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
      isToday: isSameDay(day, DateTime.now()),
      items: data.items,
      shiftSchedules: data.shifts,
      holidays: data.holidays,
      hasAlarm: data.hasAlarm,
      onTap: onTap,
    );
  }
}
