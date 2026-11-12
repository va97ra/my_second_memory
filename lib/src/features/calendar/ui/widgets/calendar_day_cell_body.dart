import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/calendar_month_data.dart';
import 'calendar_day_cell_layout.dart';
import 'calendar_day_header_row.dart';
import 'calendar_day_stamp.dart';
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
    required this.isToday,
    required this.items,
    required this.shiftSchedules,
    required this.holidays,
    required this.hasAlarm,
    required this.foreground,
    required this.todayColor,
    this.stamp,
    this.productionDay,
  });

  final DateTime date;
  final ProductionDay? productionDay;
  final String locale;
  final bool isInVisibleMonth;
  final bool isToday;
  final List<MemoryItem> items;
  final List<ShiftSchedule> shiftSchedules;
  final List<HolidayOccurrence> holidays;
  final bool hasAlarm;
  final Color foreground;

  /// Цвет кружка под сегодняшним числом.
  final Color todayColor;

  /// Водяной знак дня, если плитка закрашена.
  final String? stamp;

  @override
  Widget build(BuildContext context) {
    final hasShift = shiftSchedules.isNotEmpty && isInVisibleMonth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = CalendarDayCellLayout.forCell(
          height: constraints.maxHeight,
          items: items,
          hasHoliday: holidays.isNotEmpty,
          textScale: MediaQuery.textScalerOf(context).scale(1),
        );

        return Stack(
          children: [
            if (stamp case final label?)
              // Только на свободном цвете: между шапкой с числом и лентой
              // праздника. Шапка отступает и без смены, чтобы слово стояло
              // одинаково на всех плитках.
              Positioned(
                left: 0,
                right: 0,
                top: ShiftMarks.headerHeight,
                bottom: layout.showsHoliday ? HolidayBar.extent : 0,
                child: CalendarDayStamp(label: label),
              ),
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
              padding: EdgeInsets.only(
                top: constraints.maxHeight < 20 ? 0 : 1.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CalendarDayHeaderRow(
                    day: date.day,
                    productionDay: productionDay,
                    foreground: foreground,
                    isInVisibleMonth: isInVisibleMonth,
                    isToday: isToday,
                    hasAlarm: hasAlarm,
                    items: items,
                    todayColor: todayColor,
                  ),
                  if (layout.showsEvents) ...[
                    const SizedBox(height: 3),
                    for (final item in layout.visibleItems) ...[
                      CalendarEventBar(
                        item: item,
                        locale: locale,
                        isMuted: !isInVisibleMonth,
                      ),
                      const SizedBox(height: CalendarDayCellLayout.eventGap),
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
