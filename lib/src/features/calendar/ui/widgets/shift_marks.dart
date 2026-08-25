import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/calendar_month_data.dart';
import 'vacation_ribbon.dart';

/// Приметы смены в ячейке дня: полоса цвета сверху и лента отпуска.
///
/// Цвет занимает только полосу, а не всю ячейку: залитый целиком день спорит
/// с записями и с бумагой, и месяц от этого пестрит. День остаётся листом, а
/// график виден по кромке.
///
/// Когда графиков несколько, ячейка делится на равные доли по числу графиков —
/// и полоса, и лента отпуска живут каждая в своей доле.
class ShiftMarks extends StatelessWidget {
  const ShiftMarks({
    super.key,
    required this.schedules,
    required this.date,
  });

  /// Высота полосы. Больше — и она начинает спорить с числом дня.
  static const stripeHeight = 6.0;

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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: stripeHeight,
                  child: ColoredBox(color: Color(schedule.colorValue)),
                ),
                if (schedule.isVacationWorkday(date))
                  VacationRibbon(
                    key: ValueKey(
                      'vacation_ribbon_${schedule.id}_${calendarDateStringKey(date)}',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
