import 'package:flutter/material.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/production_preferences.dart';

import '../../state/calendar_month_data.dart';
import 'calendar_month_grid.dart';
import 'calendar_weekday_row.dart';
import 'calendar_week_numbers.dart';
import 'production_month_progress.dart';

/// Страница календаря: дни недели, сетка месяца и подсказка под ней.
class CalendarPanel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(productionPreferencesProvider);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          if (settings.showProgress)
            ProductionMonthProgress(month: visibleMonth),
          Row(children: [
            if (settings.weekNumbers)
              const SizedBox(
                  width: calendarWeekNumberWidth,
                  child: Center(child: Text('№'))),
            Expanded(child: CalendarWeekdayRow(locale: locale)),
          ]),
          const SizedBox(height: 6),
          Expanded(
            child: Row(children: [
              if (settings.weekNumbers)
                CalendarWeekNumbers(days: monthData.days),
              Expanded(
                  child: CalendarMonthGrid(
                locale: locale,
                visibleMonth: visibleMonth,
                selectedDate: selectedDate,
                monthData: monthData,
                onSelectDate: onSelectDate,
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
