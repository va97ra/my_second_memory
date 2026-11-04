import 'dart:math' as math;

import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Водяной знак на закрашенной плитке дня: слово из угла в угол свободного
/// места, чтобы было понятно, почему день этого цвета. Читалке экрана не нужен:
/// она и так называет вид дня.
class CalendarDayStamp extends StatelessWidget {
  const CalendarDayStamp({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _StampPainter(
            label: label,
            fontFamily: style.fontFamily,
          ),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  const _StampPainter({required this.label, required this.fontFamily});

  final String label;
  final String? fontFamily;

  /// Отступ слова от краёв места, доля от размера.
  static const _fill = 0.86;

  /// Кегль, на котором меряется слово. Рисуется оно уже в масштабе к месту.
  static const _measureSize = 100.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: AppPalette.dayStamp,
          fontFamily: fontFamily,
          fontSize: _measureSize,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final angle = math.atan2(size.height, size.width);
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    // Повёрнутое слово должно уместиться в место и по ширине, и по высоте.
    final scale = _fill *
        math.min(
          size.width / (text.width * cos + text.height * sin),
          size.height / (text.width * sin + text.height * cos),
        );
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-angle)
      ..scale(scale);
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
    text.dispose();
  }

  @override
  bool shouldRepaint(_StampPainter oldDelegate) =>
      label != oldDelegate.label || fontFamily != oldDelegate.fontFamily;
}
