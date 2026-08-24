import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Линейка под текстом карточки — там, где тема её рисует.
///
/// Цвет линий берётся у блокнотной темы, иначе у текстур обычной; если ни у
/// кого линий нет, содержимое остаётся как есть.
class MemoryCardRuledBackground extends StatelessWidget {
  const MemoryCardRuledBackground({
    super.key,
    required this.lineHeight,
    required this.child,
  });

  final double lineHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lineColor = NotebookVisuals.maybeOf(context)?.line ??
        AppSurfaceTextures.maybeOf(context)?.lineColor;
    if (lineColor == null) return child;

    return CustomPaint(
      painter: NotebookPaperLinesPainter(
        color: lineColor,
        top: 6 + lineHeight,
        lineHeight: lineHeight,
      ),
      child: child,
    );
  }
}
