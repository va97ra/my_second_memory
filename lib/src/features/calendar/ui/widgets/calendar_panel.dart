import 'package:flutter/material.dart';

import '../../state/calendar_month_data.dart';
import 'calendar_month_grid.dart';
import 'calendar_weekday_row.dart';

/// Страница календаря: дни недели, сетка месяца и подсказка под ней.
class CalendarPanel extends StatelessWidget {
  const CalendarPanel({
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
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          CalendarWeekdayRow(locale: locale),
          const SizedBox(height: 6),
          Expanded(
            child: CalendarMonthGrid(
              locale: locale,
              visibleMonth: visibleMonth,
              selectedDate: selectedDate,
              monthData: monthData,
              onSelectDate: onSelectDate,
            ),
          ),
        ],
      ),
    );
  }
}
