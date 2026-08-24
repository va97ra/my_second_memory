import 'package:flutter/material.dart';


/// Рамка ячейки дня.
class CalendarCellBorderPainter extends CustomPainter {
  const CalendarCellBorderPainter({
    required this.borderStart,
    required this.borderEnd,
  });

  final Color borderStart;
  final Color borderEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      const Radius.circular(8),
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
        oldDelegate.borderEnd != borderEnd;
  }
}
