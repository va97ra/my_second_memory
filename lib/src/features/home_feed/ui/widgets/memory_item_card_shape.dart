part of 'memory_item_card.dart';

/// A sheet torn out of the notebook: the left edge is ragged, the other three
/// are clean factory cuts.
class _TornPaperShapeBorder extends ShapeBorder {
  const _TornPaperShapeBorder({
    required this.variant,
    this.side = BorderSide.none,
  });

  final int variant;
  final BorderSide side;

  /// How deep the tear may bite into the card.
  static const tearDepth = 9.0;
  static const _cornerRadius = 3.0;

  /// Bite of the tear along the height, as a fraction of [tearDepth]. Values
  /// drift rather than alternate: a tear runs for a while before it turns.
  static const _profiles = <List<double>>[
    [
      0.22, 0.30, 0.18, 0.26, 0.48, 0.62, 0.54, 0.38, 0.30, //
      0.46, 0.68, 0.78, 0.60, 0.44, 0.28, 0.36, 0.24,
    ],
    [
      0.58, 0.68, 0.50, 0.40, 0.26, 0.34, 0.56, 0.72, 0.84, //
      0.66, 0.48, 0.36, 0.24, 0.32, 0.46, 0.60, 0.52,
    ],
    [
      0.42, 0.28, 0.20, 0.36, 0.54, 0.46, 0.30, 0.24, 0.44, //
      0.62, 0.76, 0.58, 0.48, 0.34, 0.26, 0.40, 0.50,
    ],
    [
      0.66, 0.54, 0.44, 0.60, 0.76, 0.66, 0.50, 0.34, 0.26, //
      0.38, 0.54, 0.44, 0.30, 0.24, 0.40, 0.58, 0.48,
    ],
  ];

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.fromLTRB(
        tearDepth,
        side.width,
        side.width,
        side.width,
      );

  @override
  ShapeBorder scale(double t) {
    return _TornPaperShapeBorder(
      variant: variant,
      side: side.scale(t),
    );
  }

  @override
  Path getInnerPath(Rect rect, {ui.TextDirection? textDirection}) {
    return getOuterPath(
      rect.deflate(side.width),
      textDirection: textDirection,
    );
  }

  @override
  Path getOuterPath(Rect rect, {ui.TextDirection? textDirection}) {
    final path = _cleanEdgePath(rect);
    _appendTornEdge(path, rect, startSubpath: false);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {ui.TextDirection? textDirection}) {
    if (side == BorderSide.none || side.width <= 0) return;
    final inner = rect.deflate(side.width / 2);
    canvas.drawPath(_cleanEdgePath(inner), side.toPaint());

    // A tear carries no drawn outline; it shows as light caught on raw fibres.
    final fibres = Path();
    _appendTornEdge(fibres, inner, startSubpath: true);
    canvas.drawPath(
      fibres,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width * 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  /// Top, right and bottom, from the torn top-left corner to the torn
  /// bottom-left one.
  Path _cleanEdgePath(Rect rect) {
    final profile = _profiles[variant % _profiles.length];
    return Path()
      ..moveTo(rect.left + profile.first * tearDepth, rect.top)
      ..lineTo(rect.right - _cornerRadius, rect.top)
      ..quadraticBezierTo(
        rect.right,
        rect.top,
        rect.right,
        rect.top + _cornerRadius,
      )
      ..lineTo(rect.right, rect.bottom - _cornerRadius)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right - _cornerRadius,
        rect.bottom,
      )
      ..lineTo(rect.left + profile.last * tearDepth, rect.bottom);
  }

  /// The ragged left edge, walked from the bottom back up to the top.
  void _appendTornEdge(Path path, Rect rect, {required bool startSubpath}) {
    final profile = _profiles[variant % _profiles.length];
    final steps = profile.length - 1;
    for (var index = steps; index >= 0; index--) {
      final x = rect.left + profile[index] * tearDepth;
      final y = rect.top + rect.height * index / steps;
      if (startSubpath && index == steps) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
  }
}

int _stablePaperVariant(String id) {
  var hash = 0x811C9DC5;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash % _TornPaperShapeBorder._profiles.length;
}
