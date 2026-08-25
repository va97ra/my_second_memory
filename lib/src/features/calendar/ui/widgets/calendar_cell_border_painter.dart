import 'package:flutter/material.dart';


/// Рамка ячейки дня.
class CalendarCellBorderPainter extends CustomPainter {
  const CalendarCellBorderPainter({
    required this.borderStart,
    required this.borderEnd,
    required this.cornerRadius,
  });

  final Color borderStart;
  final Color borderEnd;

  /// Скругление берётся у ячейки: рисованная рамка должна совпадать с той,
  /// что ячейка рисует сама.
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(cornerRadius),
    );
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [borderStart, borderEnd],
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CalendarCellBorderPainter oldDelegate) {
    return oldDelegate.borderStart != borderStart ||
        oldDelegate.borderEnd != borderEnd ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
