import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Название открытого месяца в шапке календаря. Кегль даёт шапка.
class CalendarMonthLabel extends StatelessWidget {
  const CalendarMonthLabel({
    required this.month,
    required this.locale,
    super.key,
  });

  final DateTime month;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final name = DateFormat('LLLL', locale).format(month);
    final capitalized =
        name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';

    return Text(
      '$capitalized ${month.year}',
      key: const ValueKey('calendar_month_label'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}
