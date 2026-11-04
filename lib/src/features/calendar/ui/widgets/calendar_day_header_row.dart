import 'package:ez_domain/ez_domain.dart';
import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'day_number.dart';

/// Верх ячейки дня: число, будильник и отметка архива.
class CalendarDayHeaderRow extends StatelessWidget {
  const CalendarDayHeaderRow({
    super.key,
    required this.day,
    required this.foreground,
    required this.isInVisibleMonth,
    required this.isToday,
    required this.hasAlarm,
    required this.items,
    required this.todayColor,
    this.productionDay,
  });

  final int day;
  final ProductionDay? productionDay;
  final Color foreground;
  final bool isInVisibleMonth;
  final bool isToday;
  final bool hasAlarm;
  final List<MemoryItem> items;

  /// Цвет кружка под сегодняшним числом.
  final Color todayColor;

  @override
  Widget build(BuildContext context) {
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
                isDayOff: productionDay?.isDayOff ?? false,
                isShortened: productionDay == ProductionDay.shortened,
                statusLabel: productionDay == null
                    ? null
                    : AppStrings.of(context)
                        .productionDayLabel(productionDay!.name),
                isToday: isToday,
                color: foreground,
                todayColor: todayColor,
              ),
            ),
          ),
          const Spacer(),
          // Будильник и архив жмутся к правому углу: слева место числа.
          if (hasAlarm) ...[
            Icon(
              Icons.alarm_rounded,
              size: 12.5,
              color: foreground,
            ),
            const SizedBox(width: 2),
          ],
          if (items.any((item) => item.isArchived))
            SizedBox(
              width: 9,
              height: 9,
              child: FittedBox(
                child: Icon(
                  Icons.archive_rounded,
                  color: foreground.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
