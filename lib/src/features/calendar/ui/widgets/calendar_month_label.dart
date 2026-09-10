import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Название открытого месяца в шапке календаря.
///
/// В экранных темах месяц набран крупно, а год — акцентным цветом: шапка там
/// единственная строка на весь календарь, и заголовку положено быть виден
/// сразу, а не читаться наравне с кнопками. В блокноте он остаётся прежним —
/// там над ним ещё лежит лист, и крупная надпись спорит с ним за внимание.
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
    final screen = ScreenVisuals.maybeOf(context);
    final name = DateFormat('LLLL', locale).format(month);
    final capitalized =
        name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';

    if (screen == null) {
      return Text(
        '$capitalized ${month.year}',
        key: const ValueKey('calendar_month_label'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
      );
    }

    return FittedBox(
      // Длинное название с крупным шрифтом ужимается целиком, а не теряет
      // хвост в многоточии: «Сентябрь 2026» должен читаться месяцем и годом,
      // а не «Сентяб… 2026».
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: capitalized),
            const TextSpan(text: ' '),
            TextSpan(
              text: '${month.year}',
              style: TextStyle(color: screen.colors.accent),
            ),
          ],
        ),
        key: const ValueKey('calendar_month_label'),
        maxLines: 1,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.08,
          color: screen.colors.ink,
        ),
      ),
    );
  }
}
