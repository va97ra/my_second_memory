import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../home_feed/ui/widgets/memory_item_card.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final items = ref.watch(memoryItemsControllerProvider);
    final shiftSchedules = ref.watch(shiftSchedulesControllerProvider);

    return AppShell(
      currentIndex: 1,
      child: LayoutBuilder(
        builder: (context, viewportConstraints) {
          final isLandscape =
              viewportConstraints.maxWidth > viewportConstraints.maxHeight;
          final needsLandscapeScroll =
              isLandscape && viewportConstraints.maxHeight < 680;
          final panel = _buildPanel(locale, items, shiftSchedules);

          return WarmGradientBackground(
            child: needsLandscapeScroll
                ? CustomScrollView(
                    key: const ValueKey('calendar_landscape_scroll'),
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      MainSliverAppBar(
                        title: strings.calendar,
                        backLocation: '/',
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 600,
                          child: panel,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      MainPageHeader(
                        title: strings.calendar,
                        backLocation: '/',
                      ),
                      Expanded(child: panel),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPanel(
    String locale,
    List<MemoryItem> items,
    List<ShiftSchedule> shiftSchedules,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: _CalendarPanel(
        locale: locale,
        visibleMonth: _visibleMonth,
        selectedDate: _selectedDate,
        items: items,
        shiftSchedules: shiftSchedules,
        onPreviousMonth: () => setState(() {
          _visibleMonth = DateTime(
            _visibleMonth.year,
            _visibleMonth.month - 1,
          );
        }),
        onNextMonth: () => setState(() {
          _visibleMonth = DateTime(
            _visibleMonth.year,
            _visibleMonth.month + 1,
          );
        }),
        onToday: () {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          setState(() {
            _selectedDate = today;
            _visibleMonth = DateTime(today.year, today.month);
          });
        },
        onSelectDate: _openDayDialog,
      ),
    );
  }

  Future<void> _openDayDialog(DateTime date) async {
    final selected = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDate = selected;
      _visibleMonth = DateTime(selected.year, selected.month);
    });

    context
        .go('/calendar/day?date=${DateFormat('yyyy-MM-dd').format(selected)}');
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.locale,
    required this.visibleMonth,
    required this.selectedDate,
    required this.items,
    required this.shiftSchedules,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDate,
  });

  final String locale;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<MemoryItem> items;
  final List<ShiftSchedule> shiftSchedules;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final days = _daysForMonth(visibleMonth);
    final weekDays = _weekDayLabels(locale);

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
              _CalendarShiftLegend(schedules: shiftSchedules),
              const SizedBox(height: 8),
              DecoratedBox(
                key: const ValueKey('calendar_weekdays'),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
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
                                        : const Color(0xFF475569),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
                              ? _itemsForDay(day)
                              : <MemoryItem>[];
                          final dayShiftSchedules = isInVisibleMonth
                              ? _shiftSchedulesForDay(day)
                              : <ShiftSchedule>[];
                          return _CalendarDayCell(
                            key: ValueKey('calendar_day_${_dateKey(day)}'),
                            date: day,
                            locale: locale,
                            isInVisibleMonth: isInVisibleMonth,
                            isSelected: isSameDay(day, selectedDate),
                            isToday: isSameDay(day, DateTime.now()),
                            items: dayItems,
                            shiftSchedules: dayShiftSchedules,
                            onTap: () => onSelectDate(day),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 7),
              DecoratedBox(
                key: const ValueKey('calendar_hint'),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_outlined,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.of(context).calendarTapHint,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF334155),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<MemoryItem> _itemsForDay(DateTime date) {
    return items.where((item) => isSameDay(item.memoryDate, date)).toList();
  }

  List<ShiftSchedule> _shiftSchedulesForDay(DateTime date) {
    return [
      for (final schedule in shiftSchedules)
        if (schedule.isWorkday(date)) schedule,
    ];
  }

  List<DateTime> _daysForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final leadingDays = firstDay.weekday - DateTime.monday;
    final start = firstDay.subtract(Duration(days: leadingDays));
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    return [
      for (var index = 0; index < cellCount; index++)
        DateTime(start.year, start.month, start.day + index),
    ];
  }

  List<String> _weekDayLabels(String locale) {
    if (locale == 'ru') {
      return const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    }
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
        color: const Color(0xFFFFFCF7).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDED3C5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
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
                      color: const Color(0xFF0F172A),
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
                backgroundColor: const Color(0xFFDBEAFE),
                foregroundColor: const Color(0xFF2563EB),
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
                borderRadius: BorderRadius.circular(5),
              ),
              child: const SizedBox(width: 12, height: 12),
            ),
            const SizedBox(width: 7),
            Text(
              schedule.organizationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF172033),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
            const SizedBox(width: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Text(
                  '${schedule.workDays}/${schedule.restDays}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF475569),
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
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        foregroundColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

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
    required this.onTap,
  });

  final DateTime date;
  final String locale;
  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final List<MemoryItem> items;
  final List<ShiftSchedule> shiftSchedules;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasItems = items.isNotEmpty;
    final shiftColors = [
      for (final schedule in shiftSchedules) Color(schedule.colorValue),
    ];
    final hasShift = shiftColors.isNotEmpty && isInVisibleMonth;
    final foreground = isInVisibleMonth
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.38);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _cellColor(colors, hasItems, hasShift),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : isToday
                    ? const Color(0xFF2563EB)
                    : hasItems && isInVisibleMonth
                        ? const Color(0xFFBFDBFE)
                        : isInVisibleMonth
                            ? const Color(0xFFE2E8F0)
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
                    color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, cellConstraints) {
            final maxEvents = cellConstraints.maxHeight >= 88
                ? 3
                : cellConstraints.maxHeight >= 66
                    ? 2
                    : cellConstraints.maxHeight >= 48
                        ? 1
                        : 0;
            final visibleItems = _sortedItems(items).take(maxEvents).toList();
            final overflowCount = items.length - visibleItems.length;

            return Stack(
              children: [
                if (hasShift)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
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
                          const Spacer(),
                          if (items.any((item) => item.isArchived))
                            SizedBox(
                              width: 9,
                              height: 9,
                              child: FittedBox(
                                child: Icon(
                                  Icons.archive_outlined,
                                  color: const Color(0xFF64748B).withValues(
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
                                  color: const Color(0xFF475569),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _cellColor(ColorScheme colors, bool hasItems, bool hasShift) {
    if (hasShift) {
      return Colors.white;
    }
    if (isSelected) {
      return colors.primary;
    }
    if (isToday) {
      return const Color(0xFFEAF3FF);
    }
    if (hasItems && isInVisibleMonth) {
      return const Color(0xFFF0F7FF);
    }
    if (isInVisibleMonth) {
      return const Color(0xFFF8FAFC);
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
    final content = Text(
      '$day',
      style: TextStyle(
        color: isToday || isSelected ? Colors.white : color,
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
        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(7),
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
        borderRadius: BorderRadius.circular(3),
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
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${mins.toString().padLeft(2, '0')}';
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
