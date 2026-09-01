import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Перо для рисунков инструмента: холст, размер и цвет чернил в одном месте.
///
/// Все размеры задаются долями стороны, поэтому рисунок одинаково выглядит и
/// в строке списка, и во весь экран.
class ToolPen {
  ToolPen({required this.canvas, required this.size, required this.ink});

  final Canvas canvas;
  final Size size;
  final Color ink;

  double get unit => size.shortestSide / 100;

  Paint get stroke => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4 * unit
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get thin => stroke..strokeWidth = 2.5 * unit;

  Paint get fill => Paint()..color = ink;

  Offset at(double x, double y) => Offset(size.width * x, size.height * y);

  Rect box(double left, double top, double right, double bottom) =>
      Rect.fromPoints(at(left, top), at(right, bottom));

  void line(double x1, double y1, double x2, double y2, [Paint? paint]) =>
      canvas.drawLine(at(x1, y1), at(x2, y2), paint ?? stroke);

  void rounded(Rect rect, double radius, [Paint? paint]) => canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius * unit)),
        paint ?? stroke,
      );

  void text(String value, double x, double y, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: ink, fontSize: fontSize * unit),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at(x, y));
  }
}

enum PliersJaw { flat, cutting, long }

/// Отвёртка: рукоять, стержень и шлиц. С пометкой 1000 В — изолированная.
void drawScrewdriver(ToolPen pen, {required bool marked}) {
  pen.rounded(pen.box(0.12, 0.38, 0.46, 0.62), 6);
  pen.line(0.46, 0.5, 0.82, 0.5);
  pen.line(0.82, 0.44, 0.82, 0.56);
  for (var index = 0; index < 3; index++) {
    final x = 0.18 + index * 0.08;
    pen.line(x, 0.42, x, 0.58, pen.thin);
  }
  if (marked) pen.text('1000 В', 0.12, 0.18, 16);
}

/// Пассатижи, бокорезы и длинногубцы отличаются губками, а не хватом.
void drawPliers(ToolPen pen, {required PliersJaw jaw}) {
  pen.line(0.2, 0.86, 0.5, 0.52);
  pen.line(0.36, 0.86, 0.5, 0.68);
  pen.canvas.drawCircle(pen.at(0.5, 0.52), 4 * pen.unit, pen.fill);
  switch (jaw) {
    case PliersJaw.flat:
      pen.line(0.5, 0.52, 0.78, 0.24);
      pen.line(0.5, 0.52, 0.62, 0.18);
      pen.line(0.62, 0.18, 0.78, 0.24);
    case PliersJaw.cutting:
      pen.line(0.5, 0.52, 0.74, 0.3);
      pen.line(0.5, 0.52, 0.6, 0.22);
      pen.line(0.6, 0.22, 0.74, 0.3, pen.thin);
    case PliersJaw.long:
      pen.line(0.5, 0.52, 0.88, 0.14);
      pen.line(0.5, 0.52, 0.8, 0.1);
  }
}

/// Кабельный нож: изогнутое лезвие с пяткой.
void drawKnife(ToolPen pen) {
  pen.rounded(pen.box(0.12, 0.56, 0.5, 0.76), 6);
  final blade = Path()
    ..moveTo(pen.at(0.5, 0.6).dx, pen.at(0.5, 0.6).dy)
    ..quadraticBezierTo(
      pen.at(0.82, 0.5).dx,
      pen.at(0.82, 0.5).dy,
      pen.at(0.86, 0.26).dx,
      pen.at(0.86, 0.26).dy,
    )
    ..quadraticBezierTo(
      pen.at(0.7, 0.44).dx,
      pen.at(0.7, 0.44).dy,
      pen.at(0.5, 0.72).dx,
      pen.at(0.5, 0.72).dy,
    );
  pen.canvas.drawPath(blade, pen.stroke);
}

/// Стриппер: клещи с калиброванными гнёздами.
void drawStripper(ToolPen pen) {
  pen.line(0.24, 0.88, 0.42, 0.56);
  pen.line(0.4, 0.88, 0.48, 0.62);
  pen.rounded(pen.box(0.3, 0.22, 0.76, 0.56), 6);
  for (var index = 0; index < 3; index++) {
    pen.canvas.drawCircle(
      pen.at(0.4 + index * 0.13, 0.39),
      (5 - index) * pen.unit,
      pen.thin,
    );
  }
}

/// Кримпер: пресс-клещи с профильной матрицей.
void drawCrimper(ToolPen pen) {
  pen.line(0.2, 0.88, 0.44, 0.58);
  pen.line(0.38, 0.88, 0.5, 0.64);
  pen.rounded(pen.box(0.34, 0.24, 0.74, 0.58), 6);
  pen.line(0.44, 0.32, 0.64, 0.32);
  pen.line(0.44, 0.44, 0.64, 0.44);
  pen.line(0.54, 0.32, 0.54, 0.44, pen.thin);
}

/// Измерительный прибор: корпус, экран и два щупа.
void drawMeter(ToolPen pen, {required bool highVoltage}) {
  pen.rounded(pen.box(0.22, 0.16, 0.78, 0.74), 8);
  pen.rounded(pen.box(0.3, 0.24, 0.7, 0.42), 4, pen.thin);
  pen.canvas.drawCircle(pen.at(0.5, 0.58), 8 * pen.unit, pen.thin);
  pen.line(0.5, 0.58, 0.56, 0.52, pen.thin);
  pen.line(0.34, 0.74, 0.28, 0.94);
  pen.line(0.66, 0.74, 0.72, 0.94);
  if (highVoltage) pen.text('МОм', 0.34, 0.26, 14);
}

/// Указатель напряжения: щуп с лампой.
void drawDetector(ToolPen pen) {
  pen.rounded(pen.box(0.34, 0.2, 0.66, 0.66), 8);
  pen.line(0.5, 0.66, 0.5, 0.92);
  pen.line(0.44, 0.92, 0.56, 0.92);
  pen.canvas.drawCircle(pen.at(0.5, 0.34), 7 * pen.unit, pen.thin);
  for (final angle in [-0.6, 0.0, 0.6]) {
    final from = pen.at(0.5, 0.34) + Offset.fromDirection(angle - 1.2, 11 * pen.unit);
    final to = pen.at(0.5, 0.34) + Offset.fromDirection(angle - 1.2, 17 * pen.unit);
    pen.canvas.drawLine(from, to, pen.thin);
  }
}

/// Токовые клещи: раскрывающийся магнитопровод и корпус.
void drawClampMeter(ToolPen pen) {
  final centre = pen.at(0.5, 0.34);
  final radius = 22 * pen.unit;
  pen.canvas.drawArc(
    Rect.fromCircle(center: centre, radius: radius),
    -math.pi * 0.9,
    math.pi * 1.7,
    false,
    pen.stroke,
  );
  pen.rounded(pen.box(0.32, 0.6, 0.68, 0.94), 8);
  pen.rounded(pen.box(0.38, 0.66, 0.62, 0.78), 4, pen.thin);
}

/// Перфоратор: корпус, рукоять и бур.
void drawRotaryHammer(ToolPen pen) {
  pen.rounded(pen.box(0.16, 0.3, 0.62, 0.56), 8);
  pen.rounded(pen.box(0.18, 0.56, 0.34, 0.88), 6);
  pen.line(0.62, 0.43, 0.9, 0.43);
  for (var index = 0; index < 3; index++) {
    final x = 0.68 + index * 0.07;
    pen.line(x, 0.37, x + 0.03, 0.49, pen.thin);
  }
}

/// Коронка: кольцо с зубьями и центровочное сверло.
void drawHoleSaw(ToolPen pen) {
  final centre = pen.at(0.5, 0.52);
  pen.canvas.drawCircle(centre, 30 * pen.unit, pen.stroke);
  pen.canvas.drawCircle(centre, 24 * pen.unit, pen.thin);
  for (var index = 0; index < 12; index++) {
    final angle = index * math.pi / 6;
    pen.canvas.drawLine(
      centre + Offset.fromDirection(angle, 30 * pen.unit),
      centre + Offset.fromDirection(angle, 36 * pen.unit),
      pen.thin,
    );
  }
  pen.line(0.5, 0.52, 0.5, 0.16);
}

/// Диэлектрическая перчатка.
void drawGlove(ToolPen pen) {
  final path = Path()
    ..moveTo(pen.at(0.34, 0.92).dx, pen.at(0.34, 0.92).dy)
    ..lineTo(pen.at(0.34, 0.44).dx, pen.at(0.34, 0.44).dy)
    ..quadraticBezierTo(pen.at(0.34, 0.2).dx, pen.at(0.34, 0.2).dy,
        pen.at(0.44, 0.2).dx, pen.at(0.44, 0.2).dy)
    ..quadraticBezierTo(pen.at(0.52, 0.2).dx, pen.at(0.52, 0.2).dy,
        pen.at(0.52, 0.42).dx, pen.at(0.52, 0.42).dy)
    ..lineTo(pen.at(0.66, 0.42).dx, pen.at(0.66, 0.42).dy)
    ..quadraticBezierTo(pen.at(0.76, 0.42).dx, pen.at(0.76, 0.42).dy,
        pen.at(0.76, 0.56).dx, pen.at(0.76, 0.56).dy)
    ..lineTo(pen.at(0.76, 0.92).dx, pen.at(0.76, 0.92).dy)
    ..close();
  pen.canvas.drawPath(path, pen.stroke);
  pen.line(0.44, 0.3, 0.44, 0.42, pen.thin);
}

/// Диэлектрический коврик: прямоугольник с рифлением.
void drawMat(ToolPen pen) {
  pen.rounded(pen.box(0.12, 0.3, 0.88, 0.74), 6);
  for (var index = 0; index < 5; index++) {
    final x = 0.22 + index * 0.14;
    pen.line(x, 0.36, x, 0.68, pen.thin);
  }
}

/// Защитные очки: две линзы и дужки.
void drawGoggles(ToolPen pen) {
  pen.rounded(pen.box(0.14, 0.38, 0.46, 0.62), 10);
  pen.rounded(pen.box(0.54, 0.38, 0.86, 0.62), 10);
  pen.line(0.46, 0.48, 0.54, 0.48);
  pen.line(0.14, 0.44, 0.06, 0.34, pen.thin);
  pen.line(0.86, 0.44, 0.94, 0.34, pen.thin);
}
