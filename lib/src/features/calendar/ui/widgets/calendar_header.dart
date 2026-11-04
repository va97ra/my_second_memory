import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/chrome/main_page_header.dart';
import 'calendar_month_label.dart';
import 'production_calendar_dialog.dart';
import 'shift_legend_chip.dart';

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
          // Свой прозрачный материал: без него волна нажатия уходит материалу
          // `Scaffold` и рисуется поверх задника.
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const ValueKey('production_calendar_open'),
              onTap: () => ProductionCalendarDialog.show(context, visibleMonth),
              borderRadius: BorderRadius.circular(4),
              child: Center(
                child: CalendarMonthLabel(month: visibleMonth, locale: locale),
              ),
            ),
          ),
        ),
        details: legend.isEmpty ? null : _Legend(legend),
      ),
    );
  }
}

/// Графики в одну строку: не помещаются — листаются вбок, а пока помещаются,
/// стоят посередине.
class _Legend extends StatelessWidget {
  const _Legend(this.schedules);

  final List<ShiftSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        key: const ValueKey('calendar_shift_legend'),
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: box.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final schedule in schedules)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ShiftLegendChip(schedule: schedule),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
