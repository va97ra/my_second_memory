import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Число месяца в ячейке дня.
///
/// Все числа одного размера. Сегодняшнее лежит на сплошном кружке: его видно
/// на любой бумаге и на шапке любого графика.
class DayNumber extends StatelessWidget {
  const DayNumber({
    super.key,
    required this.day,
    required this.isToday,
    required this.color,
    required this.todayColor,
    this.isDayOff = false,
    this.isShortened = false,
    this.statusLabel,
  });

  /// Размер обычного числа и сегодняшнего.
  static const fontSize = 12.5;
  static const todayFontSize = 13.5;

  /// На сколько кружок шире сегодняшнего числа.
  static const todayCircleExtra = 6.0;

  final int day;
  final bool isToday;
  final Color color;
  final Color todayColor;
  final bool isDayOff;
  final bool isShortened;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final ink = isToday ? readableInkOn(todayColor) : color;
    final content = Text(
      '$day${isShortened ? '*' : ''}',
      semanticsLabel: statusLabel == null ? null : '$day, $statusLabel',
      style: TextStyle(
        decoration: isDayOff ? TextDecoration.underline : null,
        decorationColor: ink,
        decorationThickness: 2,
        color: ink,
        fontSize: isToday ? todayFontSize : fontSize,
        fontWeight: isToday ? FontWeight.w900 : FontWeight.w800,
        height: 1,
      ),
    );

    if (!isToday) return content;

    final diameter =
        MediaQuery.textScalerOf(context).scale(todayFontSize) +
            todayCircleExtra;
    return Container(
      key: const ValueKey('calendar_today_circle'),
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: todayColor,
        // Светлый ободок отделяет кружок от шапки графика того же цвета.
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: FittedBox(fit: BoxFit.scaleDown, child: content),
      ),
    );
  }
}
