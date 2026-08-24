import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/calendar_month_data.dart';
import 'calendar_page_transition.dart';
import 'calendar_panel.dart';

/// Страницы календаря: та, что на экране, и та, что уезжает с неё.
///
/// Каждая страница читает свой месяц сама, поэтому уходящая держит свои дни до
/// конца перехода и не мигает данными нового месяца.
class CalendarMonthPages extends ConsumerWidget {
  const CalendarMonthPages({
    super.key,
    required this.locale,
    required this.visibleMonth,
    required this.outgoingMonth,
    required this.selectedDate,
    required this.showHints,
    required this.animation,
    required this.axis,
    required this.direction,
    required this.onSelectDate,
  });

  final String locale;
  final DateTime visibleMonth;
  final DateTime? outgoingMonth;
  final DateTime selectedDate;
  final bool showHints;
  final Animation<double> animation;
  final Axis axis;
  final int direction;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoing = outgoingMonth;

    return CalendarPageTransition(
      animation: animation,
      axis: axis,
      direction: direction,
      incoming: RepaintBoundary(
        key: const ValueKey('calendar_incoming_panel'),
        child: _panel(ref, visibleMonth),
      ),
      outgoing: outgoing == null
          ? null
          : RepaintBoundary(
              key: const ValueKey('calendar_outgoing_panel'),
              child: _panel(ref, outgoing),
            ),
    );
  }

  Widget _panel(WidgetRef ref, DateTime month) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: CalendarPanel(
        locale: locale,
        visibleMonth: month,
        selectedDate: selectedDate,
        monthData: ref.watch(calendarMonthDataProvider(month)),
        showHints: showHints,
        onSelectDate: onSelectDate,
      ),
    );
  }
}
