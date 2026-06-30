import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_items_controller.dart';

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

    return AppShell(
      currentIndex: 1,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(strings.calendar)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _CalendarPanel(
                locale: locale,
                visibleMonth: _visibleMonth,
                selectedDate: _selectedDate,
                items: items,
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

    context.go('/calendar/day?date=${DateFormat('yyyy-MM-dd').format(selected)}');
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.locale,
    required this.visibleMonth,
    required this.selectedDate,
    required this.items,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final String locale;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<MemoryItem> items;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final days = _daysForMonth(visibleMonth);
    final weekDays = _weekDayLabels(locale);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _capitalize(DateFormat.yMMMM(locale).format(visibleMonth)),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final label in weekDays)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return _CalendarDayCell(
                  date: day,
                  isInVisibleMonth: day.month == visibleMonth.month,
                  isSelected: isSameDay(day, selectedDate),
                  isToday: isSameDay(day, DateTime.now()),
                  itemCount: _itemsForDay(day).length,
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

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isInVisibleMonth,
    required this.isSelected,
    required this.isToday,
    required this.itemCount,
    required this.onTap,
  });

  final DateTime date;
  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected
        ? colors.onPrimary
        : isInVisibleMonth
            ? colors.onSurface
            : colors.onSurface.withValues(alpha: 0.38);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : isToday
                  ? const Color(0xFFEAF3FF)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : isToday
                    ? const Color(0xFF93C5FD)
                    : Colors.transparent,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: foreground,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            if (itemCount > 0)
              Positioned(
                right: 5,
                bottom: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected ? colors.onPrimary : colors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: itemCount > 1
                        ? Center(
                            child: Text(
                              itemCount > 9 ? '9' : '$itemCount',
                              style: TextStyle(
                                color: isSelected
                                    ? colors.primary
                                    : colors.onPrimary,
                                fontSize: 6,
                                height: 1,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
