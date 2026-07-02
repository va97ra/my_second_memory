import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_type.dart';
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
    final items = ref
        .watch(memoryItemsControllerProvider)
        .where((item) => !item.isArchived)
        .toList();
    final shiftSchedules = ref.watch(shiftSchedulesControllerProvider);

    return AppShell(
      currentIndex: 1,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(strings.calendar)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            ),
          ),
        ],
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE3EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _CalendarMonthHeader(
              locale: locale,
              visibleMonth: visibleMonth,
              onPreviousMonth: onPreviousMonth,
              onNextMonth: onNextMonth,
              onToday: onToday,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var index = 0; index < weekDays.length; index++)
                  Expanded(
                    child: Center(
                      child: Text(
                        weekDays[index],
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: index >= 5
                                      ? const Color(0xFFEA580C)
                                      : const Color(0xFF475569),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 7,
                crossAxisSpacing: 7,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isInVisibleMonth = day.month == visibleMonth.month;
                final dayItems =
                    isInVisibleMonth ? _itemsForDay(day) : <MemoryItem>[];
                final dayShiftSchedules = isInVisibleMonth
                    ? _shiftSchedulesForDay(day)
                    : <ShiftSchedule>[];
                return _CalendarDayCell(
                  key: ValueKey('calendar_day_${_dateKey(day)}'),
                  date: day,
                  isInVisibleMonth: isInVisibleMonth,
                  isSelected: isSameDay(day, selectedDate),
                  isToday: isSameDay(day, DateTime.now()),
                  itemCount: dayItems.length,
                  markerColors: _markerColorsFor(dayItems),
                  shiftSchedules: dayShiftSchedules,
                  onTap: () => onSelectDate(day),
                );
              },
            ),
          ],
        ),
      ),
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

  List<Color> _markerColorsFor(List<MemoryItem> dayItems) {
    final colors = <Color>[];
    for (final item in dayItems) {
      final color = _colorForType(item.type);
      if (!colors.contains(color)) {
        colors.add(color);
      }
      if (colors.length == 3) {
        break;
      }
    }
    return colors;
  }

  List<DateTime> _daysForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final leadingDays = firstDay.weekday - DateTime.monday;
    final start = firstDay.subtract(Duration(days: leadingDays));

    return [
      for (var index = 0; index < 42; index++)
        DateTime(start.year, start.month, start.day + index),
    ];
  }

  List<String> _weekDayLabels(String locale) {
    if (locale == 'ru') {
      return const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    }
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  Color _colorForType(MemoryType type) {
    return switch (type) {
      MemoryType.task => const Color(0xFF16A34A),
      MemoryType.note => const Color(0xFF2563EB),
      MemoryType.voiceNote => const Color(0xFFDB2777),
      MemoryType.event => const Color(0xFF7C3AED),
      MemoryType.person => const Color(0xFF0891B2),
      MemoryType.habit => const Color(0xFF059669),
      MemoryType.goal => const Color(0xFFEA580C),
      MemoryType.project => const Color(0xFF4F46E5),
      MemoryType.purchase => const Color(0xFFCA8A04),
      MemoryType.document => const Color(0xFF475569),
      MemoryType.place => const Color(0xFFDC2626),
    };
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 132,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/memory_banner.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFDBEAFE).withValues(alpha: 0.96),
                      const Color(0xFFE0F2FE).withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.24),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _MonthIconButton(
                          tooltip: 'Предыдущий месяц',
                          icon: Icons.chevron_left,
                          onPressed: onPreviousMonth,
                        ),
                        const Spacer(),
                        _MonthIconButton(
                          tooltip: 'Следующий месяц',
                          icon: Icons.chevron_right,
                          onPressed: onNextMonth,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _capitalize(month),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.tonalIcon(
                          onPressed: onToday,
                          icon: const Icon(Icons.today, size: 18),
                          label: const Text('Сегодня'),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.88),
                            foregroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
        fixedSize: const Size(42, 42),
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
    required this.isInVisibleMonth,
    required this.isSelected,
    required this.isToday,
    required this.itemCount,
    required this.markerColors,
    required this.shiftSchedules,
    required this.onTap,
  });

  final DateTime date;
  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final int itemCount;
  final List<Color> markerColors;
  final List<ShiftSchedule> shiftSchedules;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasItems = itemCount > 0;
    final shiftColors = [
      for (final schedule in shiftSchedules) Color(schedule.colorValue),
    ];
    final hasShift = shiftColors.isNotEmpty && isInVisibleMonth;
    final foreground = isSelected && !hasShift
        ? colors.onPrimary
        : isInVisibleMonth
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
                ? colors.primary
                : isToday
                    ? const Color(0xFF2563EB)
                    : hasItems && isInVisibleMonth
                        ? const Color(0xFFBFDBFE)
                        : isInVisibleMonth
                            ? const Color(0xFFE2E8F0)
                            : Colors.transparent,
            width: isToday || isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Stack(
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
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
            if (itemCount > 0)
              Positioned(
                left: 5,
                right: 5,
                bottom: 5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final color in markerColors)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.2),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.onPrimary : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (itemCount > 1)
                        Container(
                          margin: const EdgeInsets.only(left: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          height: 14,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.onPrimary
                                : const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Text(
                              itemCount > 9 ? '9+' : '$itemCount',
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : colors.onPrimary,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (isToday && !isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const SizedBox(width: 6, height: 6),
                ),
              ),
          ],
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
            ? 0.48
            : 0.4
        : isSelected
            ? 0.78
            : 0.62;

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
