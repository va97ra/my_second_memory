import 'package:flutter/material.dart';

/// Условные обозначения, нарисованные в приложении.
///
/// Рисунок, а не картинка: он живёт в обеих темах, не занимает места в
/// сборке и не мылится при увеличении. Начертания — по ГОСТ 21.614-88
/// «Изображения условные графические электрооборудования и проводок на
/// планах»; сверка по тексту стандарта не проводилась.
enum ElectricianSymbol {
  line,
  neutral,
  protectiveEarth,
  socket,
  switchOne,
  lamp,
  breaker,
  residualCurrentDevice,
  junctionBox,
  distributionBoard,
  wireJoint,
  wireCrossing,
}

/// Обозначение по имени из карточки. `null` — рисунка у карточки нет.
ElectricianSymbol? electricianSymbolByName(String name) {
  for (final value in ElectricianSymbol.values) {
    if (value.name == name) return value;
  }
  return null;
}

class ElectricianSymbolArt extends StatelessWidget {
  const ElectricianSymbolArt({
    required this.symbol,
    this.size = 96,
    super.key,
  });

  final ElectricianSymbol symbol;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _SymbolPainter(
            symbol: symbol,
            ink: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
}

class _SymbolPainter extends CustomPainter {
  const _SymbolPainter({required this.symbol, required this.ink});

  final ElectricianSymbol symbol;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 100;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * unit
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = ink;
    final centre = Offset(size.width / 2, size.height / 2);
    switch (symbol) {
      case ElectricianSymbol.line:
        _conductor(canvas, size, stroke, fill, unit, 'L', 1);
      case ElectricianSymbol.neutral:
        _conductor(canvas, size, stroke, fill, unit, 'N', 2);
      case ElectricianSymbol.protectiveEarth:
        _protectiveEarth(canvas, size, stroke, unit);
      case ElectricianSymbol.socket:
        _socket(canvas, size, stroke, unit);
      case ElectricianSymbol.switchOne:
        _switch(canvas, size, stroke, fill, unit);
      case ElectricianSymbol.lamp:
        _lamp(canvas, centre, stroke, unit);
      case ElectricianSymbol.breaker:
        _breaker(canvas, size, stroke, fill, unit);
      case ElectricianSymbol.residualCurrentDevice:
        _rcd(canvas, size, stroke, fill, unit);
      case ElectricianSymbol.junctionBox:
        _junctionBox(canvas, centre, stroke, unit);
      case ElectricianSymbol.distributionBoard:
        _board(canvas, size, stroke, unit);
      case ElectricianSymbol.wireJoint:
        _wireJoint(canvas, centre, stroke, fill, unit);
      case ElectricianSymbol.wireCrossing:
        _wireCrossing(canvas, centre, stroke, unit);
    }
  }

  /// Проводник: линия и число косых штрихов по числу жил.
  void _conductor(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint fill,
    double unit,
    String label,
    int strokes,
  ) {
    final y = size.height * 0.55;
    canvas.drawLine(
      Offset(size.width * 0.1, y),
      Offset(size.width * 0.9, y),
      stroke,
    );
    for (var index = 0; index < strokes; index++) {
      final x = size.width * (0.45 + index * 0.09);
      canvas.drawLine(
        Offset(x - 6 * unit, y + 9 * unit),
        Offset(x + 6 * unit, y - 9 * unit),
        stroke,
      );
    }
    _text(canvas, label, Offset(size.width * 0.1, size.height * 0.18), unit);
  }

  void _protectiveEarth(Canvas canvas, Size size, Paint stroke, double unit) {
    final x = size.width / 2;
    canvas.drawLine(
      Offset(x, size.height * 0.15),
      Offset(x, size.height * 0.55),
      stroke,
    );
    for (var index = 0; index < 3; index++) {
      final width = size.width * (0.34 - index * 0.09);
      final y = size.height * (0.6 + index * 0.12);
      canvas.drawLine(Offset(x - width, y), Offset(x + width, y), stroke);
    }
  }

  /// Штепсельная розетка: полукруг на линии проводки.
  void _socket(Canvas canvas, Size size, Paint stroke, double unit) {
    final base = size.height * 0.68;
    final radius = size.width * 0.26;
    canvas.drawLine(
      Offset(size.width / 2, base),
      Offset(size.width / 2, size.height * 0.95),
      stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, base), radius: radius),
      3.14159,
      3.14159,
      false,
      stroke,
    );
    canvas.drawLine(
      Offset(size.width / 2 - radius, base),
      Offset(size.width / 2 + radius, base),
      stroke,
    );
  }

  /// Однополюсный выключатель: кружок с рычажком.
  void _switch(Canvas canvas, Size size, Paint stroke, Paint fill, double u) {
    final centre = Offset(size.width / 2, size.height * 0.62);
    canvas.drawLine(
      centre,
      Offset(size.width / 2, size.height * 0.95),
      stroke,
    );
    canvas.drawCircle(centre, size.width * 0.07, fill);
    canvas.drawLine(
      centre,
      Offset(size.width * 0.82, size.height * 0.3),
      stroke,
    );
  }

  /// Светильник: круг с диагоналями.
  void _lamp(Canvas canvas, Offset centre, Paint stroke, double unit) {
    final radius = 26 * unit;
    canvas.drawCircle(centre, radius, stroke);
    final diagonal = radius * 0.7071;
    canvas.drawLine(
      centre + Offset(-diagonal, -diagonal),
      centre + Offset(diagonal, diagonal),
      stroke,
    );
    canvas.drawLine(
      centre + Offset(-diagonal, diagonal),
      centre + Offset(diagonal, -diagonal),
      stroke,
    );
  }

  /// Автоматический выключатель: контакт с косым рычагом и крестом привода.
  void _breaker(Canvas canvas, Size size, Paint stroke, Paint fill, double u) {
    final bottom = Offset(size.width * 0.35, size.height * 0.85);
    final top = Offset(size.width * 0.35, size.height * 0.15);
    canvas.drawLine(bottom, Offset(bottom.dx, size.height * 0.7), stroke);
    canvas.drawLine(top, Offset(top.dx, size.height * 0.3), stroke);
    canvas.drawCircle(Offset(bottom.dx, size.height * 0.7), 4 * u, fill);
    canvas.drawLine(
      Offset(bottom.dx, size.height * 0.7),
      Offset(size.width * 0.62, size.height * 0.28),
      stroke,
    );
    final cross = Offset(size.width * 0.62, size.height * 0.28);
    canvas.drawLine(cross + Offset(-7 * u, -7 * u), cross + Offset(7 * u, 7 * u), stroke);
    canvas.drawLine(cross + Offset(-7 * u, 7 * u), cross + Offset(7 * u, -7 * u), stroke);
  }

  /// УЗО: два проводника и охватывающий их трансформатор тока.
  void _rcd(Canvas canvas, Size size, Paint stroke, Paint fill, double unit) {
    for (final x in [size.width * 0.38, size.width * 0.62]) {
      canvas.drawLine(
        Offset(x, size.height * 0.12),
        Offset(x, size.height * 0.88),
        stroke,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.62,
        height: size.height * 0.34,
      ),
      stroke,
    );
  }

  /// Распределительная коробка: круг с тремя отводами.
  void _junctionBox(Canvas canvas, Offset centre, Paint stroke, double unit) {
    final radius = 24 * unit;
    canvas.drawCircle(centre, radius, stroke);
    for (final angle in [-1.5708, 0.5236, 2.618]) {
      final direction = Offset.fromDirection(angle, radius * 1.7);
      canvas.drawLine(centre + direction / 1.7 * 1.0, centre + direction, stroke);
    }
  }

  /// Щит: прямоугольник с закрашенной половиной.
  void _board(Canvas canvas, Size size, Paint stroke, double unit) {
    final rect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.4,
    );
    canvas.drawRect(rect, stroke);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width / 3, rect.height),
      Paint()..color = ink.withValues(alpha: 0.35),
    );
  }

  /// Соединение проводников: точка на пересечении.
  void _wireJoint(
    Canvas canvas,
    Offset centre,
    Paint stroke,
    Paint fill,
    double unit,
  ) {
    canvas.drawLine(
      centre + Offset(-34 * unit, 0),
      centre + Offset(34 * unit, 0),
      stroke,
    );
    canvas.drawLine(centre, centre + Offset(0, 34 * unit), stroke);
    canvas.drawCircle(centre, 6 * unit, fill);
  }

  /// Пересечение без соединения: точки нет.
  void _wireCrossing(Canvas canvas, Offset centre, Paint stroke, double unit) {
    canvas.drawLine(
      centre + Offset(-34 * unit, 0),
      centre + Offset(34 * unit, 0),
      stroke,
    );
    canvas.drawLine(
      centre + Offset(0, -34 * unit),
      centre + Offset(0, 34 * unit),
      stroke,
    );
  }

  void _text(Canvas canvas, String value, Offset at, double unit) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: ink, fontSize: 22 * unit),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_SymbolPainter oldDelegate) =>
      oldDelegate.symbol != symbol || oldDelegate.ink != ink;
}
