import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'day_number.dart';

/// Верх ячейки дня: число, будильник и отметка архива.
class CalendarDayHeaderRow extends StatelessWidget {
  const CalendarDayHeaderRow({
    super.key,
    required this.day,
    required this.foreground,
    required this.isInVisibleMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasAlarm,
    required this.items,
  });

  final int day;
  final Color foreground;
  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasAlarm;
  final List<MemoryItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: DayNumber(
                day: day,
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
              color: isSelected || isToday ? colors.onPrimary : foreground,
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
                  color: colors.onSurfaceVariant.withValues(
                    alpha: isInVisibleMonth ? 0.8 : 0.35,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
