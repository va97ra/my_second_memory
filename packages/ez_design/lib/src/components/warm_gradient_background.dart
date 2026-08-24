import 'package:flutter/material.dart';

/// Фон экрана.
///
/// Оболочка рисует общий фон один раз, поэтому обёртка экрана остаётся
/// прозрачной: иначе одна и та же текстура декодируется и рисуется дважды.
class WarmGradientBackground extends StatelessWidget {
  const WarmGradientBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The app shell owns the shared background. Keeping screen wrappers
    // transparent avoids decoding and painting the same texture twice.
    return child;
  }
}
