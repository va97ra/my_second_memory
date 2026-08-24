part of '../calendar_screen.dart';

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    super.key,
    required this.date,
    required this.locale,
    required this.isInVisibleMonth,
    required this.isSelected,
    required this.isToday,
    required this.items,
    required this.shiftSchedules,
    required this.holidays,
    required this.hasAlarm,
    required this.onTap,
  });

  final DateTime date;
  final String locale;
  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final List<MemoryItem> items;
  final List<ShiftSchedule> shiftSchedules;
  final List<HolidayOccurrence> holidays;
  final bool hasAlarm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A day cell is loose paper too, so it keeps the light scheme on the dark
    // notebook and reads its own ink rather than the page's.
    return NotebookPaperIsland(child: Builder(builder: _buildCell));
  }

  Widget _buildCell(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = AppSurfacePalette.of(context);
    final hasItems = items.isNotEmpty;
    final hasShift = shiftSchedules.isNotEmpty && isInVisibleMonth;
    final foreground = isInVisibleMonth
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.38);

    final usesGradientBorder =
        isInVisibleMonth && !isSelected && !isToday && !hasItems;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: usesGradientBorder
            ? CalendarCellBorderPainter(
                borderStart: palette.borderStart,
                borderEnd: palette.borderEnd,
              )
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            gradient: isSelected
                ? palette.accentGradient
                : isInVisibleMonth
                    ? palette.surfaceGradient(
                        base: _cellColor(colors, palette, hasShift),
                      )
                    : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday
                  ? colors.primary
                  : isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : hasItems && isInVisibleMonth
                          ? colors.outline
                          : Colors.transparent,
              width: isToday
                  ? 2.5
                  : isSelected
                      ? 2
                      : 1,
            ),
            boxShadow: isSelected || isToday
                ? [
                    BoxShadow(
                      color: (isToday ? colors.primary : colors.onSurface)
                          .withValues(alpha: isToday ? 0.34 : 0.16),
                      blurRadius: isToday ? 10 : 14,
                      spreadRadius: isToday ? 1 : 0,
                      offset: Offset(0, isToday ? 2 : 7),
                    ),
                  ]
                : NotebookVisuals.maybeOf(context) == null
                    ? null
                    : notebookSurfaceShadow(
                        context,
                        NotebookSurfaceDepth.tile,
                      ),
          ),
          child: LayoutBuilder(
            builder: (context, cellConstraints) {
              final layout = CalendarDayCellLayout.forCell(
                height: cellConstraints.maxHeight,
                items: items,
                hasHoliday: holidays.isNotEmpty,
              );

              return Stack(
                children: [
                  if (hasShift)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ShiftFill(
                          key: ValueKey('shift_fill_${_dateKey(date)}'),
                          schedules: shiftSchedules,
                          date: date,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: DayNumber(
                                    day: date.day,
                                    isToday: isToday,
                                    isSelected: isSelected,
                                    color: foreground,
                                  ),
                                ),
                              ),
                              if (hasAlarm) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.alarm_rounded,
                                  size: 12.5,
                                  color: isSelected || isToday
                                      ? colors.onPrimary
                                      : foreground,
                                ),
                              ],
                              const Spacer(),
                              if (items.any((item) => item.isArchived))
                                SizedBox(
                                  width: 9,
                                  height: 9,
                                  child: FittedBox(
                                    child: Icon(
                                      Icons.archive_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(
                                            alpha:
                                                isInVisibleMonth ? 0.8 : 0.35,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (layout.showsEvents) ...[
                          const SizedBox(height: 3),
                          for (final item in layout.visibleItems) ...[
                            CalendarEventBar(
                              item: item,
                              locale: locale,
                              isMuted: !isInVisibleMonth,
                            ),
                            const SizedBox(height: 1),
                          ],
                          if (layout.showsOverflow &&
                              cellConstraints.maxHeight >= 48)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                locale == 'ru'
                                    ? '+ ещё ${layout.overflowCount}'
                                    : '+ ${layout.overflowCount} more',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                              ),
                            ),
                          if (layout.showsHoliday) ...[
                            const Spacer(),
                            HolidayBar(
                              locale: locale,
                              isMuted: !isInVisibleMonth,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _cellColor(
    ColorScheme colors,
    AppSurfacePalette palette,
    bool hasShift,
  ) {
    if (hasShift) {
      return colors.surface;
    }
    if (isToday) {
      return Color.alphaBlend(
        colors.primary.withValues(alpha: 0.16),
        palette.calendarTile,
      );
    }
    // Заливка одна и та же независимо от того, есть ли в дне записи: их
    // наличие показывает рамка, а не фон.
    return isInVisibleMonth ? palette.calendarTile : Colors.transparent;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

