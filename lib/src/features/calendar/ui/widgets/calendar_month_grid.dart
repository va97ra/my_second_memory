import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../state/calendar_month_data.dart';
import 'calendar_day_slot.dart';

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
    return CalendarDaySlot(
      key: ValueKey('calendar_day_${calendarDateStringKey(day)}'),
      day: day,
      locale: locale,
      visibleMonth: visibleMonth,
      onTap: () => onSelectDate(day),
    );
  }
}
