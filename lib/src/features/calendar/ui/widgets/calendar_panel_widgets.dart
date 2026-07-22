part of '../calendar_screen.dart';

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.locale,
    required this.visibleMonth,
    required this.selectedDate,
    required this.monthData,
    required this.showHints,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDate,
  });

  final String locale;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final CalendarMonthData monthData;
  final bool showHints;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final days = monthData.days;
    final weekDays = calendarWeekdayLabels(locale);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              _CalendarMonthHeader(
                locale: locale,
                visibleMonth: visibleMonth,
                onPreviousMonth: onPreviousMonth,
                onNextMonth: onNextMonth,
                onToday: onToday,
              ),
              _CalendarShiftLegend(schedules: monthData.shiftSchedules),
              const SizedBox(height: 8),
              if (NotebookVisuals.maybeOf(context) == null)
                DecoratedBox(
                  key: const ValueKey('calendar_weekdays'),
                  decoration: BoxDecoration(
                    color: AppSurfacePalette.of(context).weekdaySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        for (var index = 0; index < weekDays.length; index++)
                          Expanded(
                            child: Center(
                              child: Text(
                                weekDays[index],
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: index >= 5
                                          ? const Color(0xFFEA580C)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  key: const ValueKey('calendar_weekdays'),
                  height: 28,
                  child: Row(
                    children: [
                      for (var index = 0; index < weekDays.length; index++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == weekDays.length - 1 ? 0 : 2,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppSurfacePalette.of(context)
                                        .weekdaySurface
                                        .withValues(alpha: 0.96),
                                    AppSurfacePalette.of(context)
                                        .weekdaySurface,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                boxShadow: notebookSurfaceShadow(
                                  context,
                                  NotebookSurfaceDepth.tile,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  weekDays[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: index >= 5
                                            ? const Color(0xFFEA580C)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, gridConstraints) {
                    const spacing = 2.0;
                    final rowCount = days.length ~/ 7;
                    final cellWidth =
                        (gridConstraints.maxWidth - spacing * 6) / 7;
                    final cellHeight =
                        (gridConstraints.maxHeight - spacing * (rowCount - 1)) /
                            rowCount;

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
                        itemBuilder: (context, index) {
                          final day = days[index];
                          final isInVisibleMonth =
                              day.month == visibleMonth.month;
                          final dayItems = isInVisibleMonth
                              ? monthData.itemsByDay[calendarDateKey(day)] ??
                                  const <MemoryItem>[]
                              : <MemoryItem>[];
                          final dayShiftSchedules = isInVisibleMonth
                              ? monthData.shiftsByDay[calendarDateKey(day)] ??
                                  const <ShiftSchedule>[]
                              : <ShiftSchedule>[];
                          final dayHolidays = isInVisibleMonth
                              ? monthData.holidaysByDay[calendarDateKey(day)] ??
                                  const <HolidayOccurrence>[]
                              : const <HolidayOccurrence>[];
                          return _CalendarDayCell(
                            key: ValueKey(
                              'calendar_day_${calendarDateStringKey(day)}',
                            ),
                            date: day,
                            locale: locale,
                            isInVisibleMonth: isInVisibleMonth,
                            isSelected: isSameDay(day, selectedDate),
                            isToday: isSameDay(day, DateTime.now()),
                            items: dayItems,
                            shiftSchedules: dayShiftSchedules,
                            holidays: dayHolidays,
                            hasAlarm: isInVisibleMonth &&
                                monthData.alarmDays
                                    .contains(calendarDateKey(day)),
                            onTap: () => onSelectDate(day),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              if (showHints) ...[
                const SizedBox(height: 7),
                DecoratedBox(
                  key: const ValueKey('calendar_hint'),
                  decoration: BoxDecoration(
                    color: AppSurfacePalette.of(context).raisedSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppSurfacePalette.of(context).borderStart,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.of(context).calendarTapHint,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CalendarMonthHeader extends StatelessWidget {
  const _CalendarMonthHeader({
    required this.locale,
    required this.visibleMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  final String locale;
  final DateTime visibleMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final month = DateFormat.yMMMM(locale).format(visibleMonth);
    final strings = AppStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSurfacePalette.of(context).panelSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            _MonthIconButton(
              tooltip: strings.previousMonth,
              icon: Icons.chevron_left,
              onPressed: onPreviousMonth,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _capitalize(month),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
              ),
            ),
            const SizedBox(width: 7),
            IconButton.filledTonal(
              tooltip: strings.today,
              onPressed: onToday,
              icon: const Icon(Icons.today),
              style: IconButton.styleFrom(
                fixedSize: const Size(40, 40),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _MonthIconButton(
              tooltip: strings.nextMonth,
              icon: Icons.chevron_right,
              onPressed: onNextMonth,
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _CalendarShiftLegend extends StatelessWidget {
  const _CalendarShiftLegend({required this.schedules});

  final List<ShiftSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final enabledSchedules = [
      for (final schedule in schedules)
        if (schedule.isEnabled) schedule,
    ];

    if (enabledSchedules.isEmpty) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final schedule in enabledSchedules)
              _ShiftLegendChip(schedule: schedule),
          ],
        ),
      ),
    );
  }
}

class _ShiftLegendChip extends StatelessWidget {
  const _ShiftLegendChip({required this.schedule});

  final ShiftSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final color = Color(schedule.colorValue);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(width: 12, height: 12),
            ),
            const SizedBox(width: 7),
            Text(
              schedule.organizationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
            const SizedBox(width: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Text(
                  '${schedule.workDays}/${schedule.restDays}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthIconButton extends StatelessWidget {
  const _MonthIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
