import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'shift_legend_chip.dart';

/// Графики в одну строку: не помещаются — листаются вбок, а пока помещаются,
/// стоят посередине.
class CalendarShiftLegend extends StatelessWidget {
  const CalendarShiftLegend(this.schedules, {super.key});

  final List<ShiftSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        key: const ValueKey('calendar_shift_legend'),
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: box.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final schedule in schedules)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ShiftLegendChip(schedule: schedule),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
