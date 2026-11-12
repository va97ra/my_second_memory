import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/chrome/main_page_header.dart';
import 'calendar_month_label.dart';
import 'calendar_shift_legend.dart';
import 'production_calendar_dialog.dart';

/// Шапка календаря: стрелки по краям, посередине месяц и графики смен, которые
/// его красят.
class CalendarHeader extends StatelessWidget {
  const CalendarHeader({
    super.key,
    required this.visibleMonth,
    required this.locale,
    required this.schedules,
    required this.onToday,
    required this.onChangeMonth,
  });

  final DateTime visibleMonth;
  final String locale;
  final List<ShiftSchedule> schedules;
  final VoidCallback onToday;
  final ValueChanged<int> onChangeMonth;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final legend = [
      for (final schedule in schedules)
        if (schedule.isEnabled) schedule,
    ];

    return MainPageHeader(
      cardKey: const ValueKey('calendar_header_card'),
      hint: strings.calendarPageHint,
      leading: [
        IconButton(
          key: const ValueKey('calendar_previous_month'),
          tooltip: strings.previousMonth,
          onPressed: () => onChangeMonth(-1),
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
          style: notebookIconButtonStyle(),
        ),
      ],
      trailing: [
        IconButton(
          key: const ValueKey('calendar_today'),
          tooltip: strings.today,
          onPressed: onToday,
          icon: const Icon(Icons.today_rounded, size: 22),
          style: notebookIconButtonStyle(),
        ),
        IconButton(
          key: const ValueKey('calendar_next_month'),
          tooltip: strings.nextMonth,
          onPressed: () => onChangeMonth(1),
          icon: const Icon(Icons.chevron_right_rounded, size: 24),
          style: notebookIconButtonStyle(),
        ),
      ],
      center: NotebookHeaderTitle(
        title: Tooltip(
          message: strings.productionCalendar,
          child: NotebookPressable(
            key: const ValueKey('production_calendar_open'),
            onTap: () => ProductionCalendarDialog.show(context, visibleMonth),
            borderRadius: BorderRadius.circular(4),
            child: Center(
              child: CalendarMonthLabel(month: visibleMonth, locale: locale),
            ),
          ),
        ),
        details: legend.isEmpty ? null : CalendarShiftLegend(legend),
      ),
    );
  }
}
