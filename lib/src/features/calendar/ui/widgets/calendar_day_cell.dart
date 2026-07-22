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
    final colors = Theme.of(context).colorScheme;
    final palette = AppSurfacePalette.of(context);
    final hasItems = items.isNotEmpty;
    final shiftColors = [
      for (final schedule in shiftSchedules) Color(schedule.colorValue),
    ];
    final hasShift = shiftColors.isNotEmpty && isInVisibleMonth;
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
            ? _CalendarCellBorderPainter(
                borderStart: palette.borderStart,
                borderEnd: palette.borderEnd,
              )
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: isSelected
                ? null
                : _cellColor(colors, palette, hasItems, hasShift),
            gradient: isSelected ? palette.accentGradient : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : isToday
                      ? colors.primary
                      : hasItems && isInVisibleMonth
                          ? colors.outline
                          : Colors.transparent,
              width: isSelected
                  ? 2
                  : isToday
                      ? 1.5
                      : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
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
              final maxEvents = cellConstraints.maxHeight >= 130
                  ? 5
                  : cellConstraints.maxHeight >= 112
                      ? 4
                      : cellConstraints.maxHeight >= 94
                          ? 3
                          : cellConstraints.maxHeight >= 76
                              ? 2
                              : cellConstraints.maxHeight >= 58
                                  ? 1
                                  : 0;
              final holidaySlots = holidays.isEmpty || maxEvents == 0 ? 0 : 1;
              final itemSlots = maxEvents - holidaySlots;
              final needsOverflow = items.length > itemSlots;
              final visibleItemSlots = needsOverflow
                  ? (itemSlots - 1).clamp(0, itemSlots)
                  : itemSlots;
              final visibleItems =
                  _sortedItems(items).take(visibleItemSlots).toList();
              final overflowCount = items.length - visibleItems.length;

              return Stack(
                children: [
                  if (hasShift)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _ShiftFill(
                          key: ValueKey('shift_fill_${_dateKey(date)}'),
                          colors: shiftColors,
                          isSelected: isSelected,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _DayNumber(
                              day: date.day,
                              isToday: isToday,
                              isSelected: isSelected,
                              color: foreground,
                            ),
                            if (hasAlarm) ...[
                              const SizedBox(width: 2),
                              Icon(
                                Icons.alarm_outlined,
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
                                    Icons.archive_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(
                                          alpha: isInVisibleMonth ? 0.8 : 0.35,
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (maxEvents > 0) ...[
                          const SizedBox(height: 3),
                          for (final item in visibleItems) ...[
                            _CalendarEventBar(
                              item: item,
                              locale: locale,
                              isMuted: !isInVisibleMonth,
                            ),
                            const SizedBox(height: 2),
                          ],
                          if (overflowCount > 0 &&
                              cellConstraints.maxHeight >= 70)
                            Text(
                              locale == 'ru'
                                  ? '+ ещё $overflowCount'
                                  : '+ $overflowCount more',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                            ),
                          if (holidays.isNotEmpty && maxEvents > 0) ...[
                            const Spacer(),
                            _HolidayBar(
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
    bool hasItems,
    bool hasShift,
  ) {
    if (hasShift) {
      return colors.surface;
    }
    if (isToday) {
      return palette.calendarTile;
    }
    if (hasItems && isInVisibleMonth) {
      return palette.calendarTile;
    }
    if (isInVisibleMonth) {
      return palette.calendarTile;
    }
    return Colors.transparent;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<MemoryItem> _sortedItems(List<MemoryItem> source) {
    return [...source]..sort((a, b) {
        final aTime = a.timeMinutes;
        final bTime = b.timeMinutes;
        if (aTime != null && bTime != null && aTime != bTime) {
          return aTime.compareTo(bTime);
        }
        if (aTime != null && bTime == null) {
          return -1;
        }
        if (aTime == null && bTime != null) {
          return 1;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
  }
}

class _HolidayBar extends StatelessWidget {
  const _HolidayBar({required this.locale, required this.isMuted});

  final String locale;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFD97706).withValues(
      alpha: isMuted ? 0.5 : 1,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Text(
          locale == 'ru' ? 'Праздник' : 'Holiday',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: Colors.white,
            fontSize: 7.2,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(-0.6, 0)),
              Shadow(color: Colors.black, offset: Offset(0.6, 0)),
              Shadow(color: Colors.black, offset: Offset(0, 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarCellBorderPainter extends CustomPainter {
  const _CalendarCellBorderPainter({
    required this.borderStart,
    required this.borderEnd,
  });

  final Color borderStart;
  final Color borderEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      const Radius.circular(8),
    );
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [borderStart, borderEnd],
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CalendarCellBorderPainter oldDelegate) {
    return oldDelegate.borderStart != borderStart ||
        oldDelegate.borderEnd != borderEnd;
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.color,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = AppSurfacePalette.of(context);
    final content = Text(
      '$day',
      style: TextStyle(
        color: isSelected
            ? colors.onPrimary
            : isToday
                ? colors.onPrimary
                : color,
        fontSize: 12.5,
        fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w800,
        height: 1,
      ),
    );

    if (!isToday && !isSelected) {
      return content;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? colors.onPrimary.withValues(alpha: 0.18) : null,
        gradient: isSelected ? null : palette.accentGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: content,
      ),
    );
  }
}

class _CalendarEventBar extends StatelessWidget {
  const _CalendarEventBar({
    required this.item,
    required this.locale,
    required this.isMuted,
  });

  final MemoryItem item;
  final String locale;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final color = memoryTypeColor(item.type);
    final barColor = isMuted ? color.withValues(alpha: 0.48) : color;
    final title = _recordTitle(item, locale);
    final time = _formatTime(item.timeMinutes);
    final text = time == null ? title : '$time $title';

    return DecoratedBox(
      key: ValueKey('calendar_event_bar_${item.id}'),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: _OutlinedCalendarText(text: text),
      ),
    );
  }

  String? _formatTime(int? minutes) {
    if (minutes == null) {
      return null;
    }
    return formatMemoryTime(minutes);
  }

  String _recordTitle(MemoryItem item, String locale) {
    final title = item.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    final body = item.body.trim();
    if (body.isNotEmpty) {
      return body.split(RegExp(r'\s+')).take(4).join(' ');
    }
    return item.type.label(locale);
  }
}

class _OutlinedCalendarText extends StatelessWidget {
  const _OutlinedCalendarText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 8.5,
      fontWeight: FontWeight.w900,
      height: 1,
    );

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle.copyWith(
        color: Colors.white,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(-0.7, 0)),
          Shadow(color: Colors.black, offset: Offset(0.7, 0)),
          Shadow(color: Colors.black, offset: Offset(0, -0.7)),
          Shadow(color: Colors.black, offset: Offset(0, 0.7)),
        ],
      ),
    );
  }
}

class _ShiftFill extends StatelessWidget {
  const _ShiftFill({
    super.key,
    required this.colors,
    required this.isSelected,
  });

  final List<Color> colors;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final alpha = colors.length == 1
        ? isSelected
            ? 0.54
            : 0.44
        : isSelected
            ? 0.86
            : 0.68;

    return Row(
      children: [
        for (final color in colors)
          Expanded(
            child: ColoredBox(
              color: color.withValues(alpha: alpha),
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}
