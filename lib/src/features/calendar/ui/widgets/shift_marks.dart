import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/calendar_month_data.dart';
import 'vacation_ribbon.dart';

/// Приметы смены в ячейке дня: цветная шапка и лента отпуска под ней.
///
/// Цвет занимает только шапку, а не всю ячейку: залитый целиком день спорит
/// с записями и с бумагой, и месяц от этого пестрит. День остаётся листом, а
/// график читается по верхней полосе, на которой и стоит число.
///
/// Когда графиков несколько, ячейка делится на равные доли по числу графиков —
/// и шапка, и лента отпуска живут каждая в своей доле.
class ShiftMarks extends StatelessWidget {
  const ShiftMarks({
    super.key,
    required this.schedules,
    required this.date,
  });

  /// Высота шапки. Держится вровень с праздничной лентой у нижнего края —
  /// две полосы одной толщины читаются как рамка листа, а не как два разных
  /// украшения. Число на шапке стоит обычного размера.
  static const headerHeight = 15.0;

  final List<ShiftSchedule> schedules;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final schedule in schedules)
          Expanded(
            child: Stack(
              key: ValueKey('shift_segment_${schedule.id}'),
              fit: StackFit.expand,
              children: [
                // Лента отпуска идёт первой: шапка ложится поверх неё, иначе
                // лента перечёркивала бы цвет графика у самой кромки.
                if (schedule.isVacationWorkday(date))
                  VacationRibbon(
                    key: ValueKey(
                      'vacation_ribbon_${schedule.id}_${calendarDateStringKey(date)}',
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: headerHeight,
                  child: ColoredBox(color: Color(schedule.colorValue)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
