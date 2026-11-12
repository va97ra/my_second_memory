import 'package:flutter/material.dart';

import 'calendar_page_transition.dart';
import 'calendar_panel.dart';
import 'calendar_year_grid.dart';

/// Страницы календаря: та, что на экране, и та, что уезжает с неё. На годовом
/// виде страница — год, и листаются годы.
///
/// Каждая страница читает свой месяц сама, поэтому уходящая держит свои дни до
/// конца перехода и не мигает данными нового месяца.
class CalendarMonthPages extends StatelessWidget {
  const CalendarMonthPages({
    super.key,
    required this.locale,
    required this.visibleMonth,
    required this.outgoingMonth,
    required this.animation,
    required this.axis,
    required this.direction,
    required this.onSelectDate,
    required this.onOpenMonth,
    this.showsYear = false,
  });

  final String locale;
  final DateTime visibleMonth;
  final DateTime? outgoingMonth;
  final Animation<double> animation;
  final Axis axis;
  final int direction;
  final ValueChanged<DateTime> onSelectDate;
  final bool showsYear;
  final ValueChanged<DateTime> onOpenMonth;

  @override
  Widget build(BuildContext context) {
    final outgoing = outgoingMonth;

    return CalendarPageTransition(
      animation: animation,
      axis: axis,
      direction: direction,
      incoming: RepaintBoundary(
        key: const ValueKey('calendar_incoming_panel'),
        child: _panel(visibleMonth),
      ),
      outgoing: outgoing == null
          ? null
          : RepaintBoundary(
              key: const ValueKey('calendar_outgoing_panel'),
              child: _panel(outgoing),
            ),
    );
  }

  Widget _panel(DateTime month) {
    if (showsYear) {
      return CalendarYearGrid(
        year: month.year,
        locale: locale,
        onOpenMonth: onOpenMonth,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: CalendarPanel(
        locale: locale,
        visibleMonth: month,
        onSelectDate: onSelectDate,
      ),
    );
  }
}
