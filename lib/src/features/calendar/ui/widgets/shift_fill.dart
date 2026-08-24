import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import '../../state/calendar_month_data.dart';
import 'vacation_ribbon.dart';

/// Заливка ячейки цветом смены.
class ShiftFill extends StatelessWidget {
  const ShiftFill({
    super.key,
    required this.schedules,
    required this.date,
  });

  final List<ShiftSchedule> schedules;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < schedules.length; index++)
          Expanded(
            child: Stack(
              key: ValueKey('shift_segment_${schedules[index].id}'),
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Color(schedules[index].colorValue)),
                if (schedules[index].isVacationWorkday(date))
                  VacationRibbon(
                    key: ValueKey(
                      'vacation_ribbon_${schedules[index].id}_${calendarDateStringKey(date)}',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
