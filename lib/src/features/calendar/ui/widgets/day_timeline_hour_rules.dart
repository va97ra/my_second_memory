import 'package:flutter/material.dart';
import 'day_timeline_geometry.dart';

/// Часы слева и линии, по которым читается время.
class HourRulesPainter extends CustomPainter {
  /// Линии и подписи рисуются чернилами — одним и тем же цветом.
  ///
  /// Цвет границ, который стоял здесь раньше, идёт от темы и повторяет её
  /// фон: на светлой теме он светлый, на тёмной тёмный — и в обеих шкала
  /// сливалась с задником. Чернила противоположны фону по определению:
  /// в «Киберпанке» линии белые, в «Космосе» чёрные, как и цифры часов.
  /// Линия чуть приглушена — их двадцать четыре, и в полную силу они спорят
  /// с записями поверх них.
  HourRulesPainter(BuildContext context)
      : _line = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.42),
        _text = Theme.of(context).colorScheme.onSurface;

  final Color _line;
  final Color _text;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = _line
      ..strokeWidth = 1;

    for (var hour = 0; hour <= 24; hour++) {
      final y = hour * dayTimelineHourHeight;
      canvas.drawLine(
        Offset(dayTimelineGutterWidth, y),
        Offset(size.width, y),
        rule,
      );
      if (hour == 24) break;
      final label = TextPainter(
        text: TextSpan(
          text: formatDayTimelineHour(hour),
          style: TextStyle(
            color: _text,
            // Крупнее и жирнее подписей внутри записей: это разметка шкалы,
            // по ней ищут глазами час, а не читают её подряд.
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(8, y + 3));
    }
  }

  @override
  bool shouldRepaint(HourRulesPainter oldDelegate) =>
      oldDelegate._line != _line || oldDelegate._text != _text;
}
