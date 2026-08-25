import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/calendar_month_data.dart';
import 'calendar_day_cell_layout.dart';
import 'calendar_day_header_row.dart';
import 'calendar_event_bar.dart';
import 'holiday_bar.dart';
import 'shift_marks.dart';

/// Содержимое ячейки дня: смена под ним, число сверху и записи под числом.
///
/// Сколько записей поместится, решает [CalendarDayCellLayout] по высоте
/// ячейки: в низкой строке не показывается ничего, кроме числа.
class CalendarDayCellBody extends StatelessWidget {
  const CalendarDayCellBody({
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
    required this.foreground,
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
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final hasShift = shiftSchedules.isNotEmpty && isInVisibleMonth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = CalendarDayCellLayout.forCell(
          height: constraints.maxHeight,
          items: items,
          hasHoliday: holidays.isNotEmpty,
        );

        return Stack(
          children: [
            if (hasShift)
              Positioned.fill(
                // Скругление ячейке обрезает сама ячейка — второй раз не надо.
                child: ShiftMarks(
                  key: ValueKey('shift_marks_${calendarDateStringKey(date)}'),
                  schedules: shiftSchedules,
                  date: date,
                ),
              ),
            Padding(
              // Число стоит на одном уровне во всех ячейках, со сменой и без:
              // в дне со сменой оно ложится на её шапку. Снизу отступа нет —
              // праздничная лента идёт вплотную к краю.
              padding: const EdgeInsets.only(top: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CalendarDayHeaderRow(
                    day: date.day,
                    foreground: foreground,
                    isInVisibleMonth: isInVisibleMonth,
                    isSelected: isSelected,
                    isToday: isToday,
                    hasAlarm: hasAlarm,
                    items: items,
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
                    if (layout.showsOverflow && constraints.maxHeight >= 48)
                      _overflowLabel(context, layout.overflowCount),
                    if (layout.showsHoliday) ...[
                      const Spacer(),
                      HolidayBar(locale: locale, isMuted: !isInVisibleMonth),
                    ] else
                      const SizedBox(height: 3),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _overflowLabel(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        locale == 'ru' ? '+ ещё $count' : '+ $count more',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}
