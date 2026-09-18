import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

class CalendarWeekNumbers extends StatelessWidget {
  const CalendarWeekNumbers({super.key, required this.days});
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SizedBox(
      width: calendarWeekNumberWidth,
      child: Column(children: [
        for (var row = 0; row < days.length ~/ 7; row++) ...[
          if (row > 0) const SizedBox(height: calendarGridSpacing),
          Expanded(
              child: Center(
                  child: Semantics(
            label: strings.calendarWeek(
                isoWeek(days[row * 7]).number, isoWeek(days[row * 7]).year),
            child: ExcludeSemantics(
                child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${isoWeek(days[row * 7]).number}',
                key: ValueKey('calendar_week_$row'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            )),
          ))),
        ],
      ]),
    );
  }
}
