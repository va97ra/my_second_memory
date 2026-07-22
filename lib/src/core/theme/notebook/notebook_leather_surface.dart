import 'package:flutter/material.dart';

import 'notebook_assets.dart';
import 'notebook_visuals.dart';

class NotebookLeatherSurface extends StatelessWidget {
  const NotebookLeatherSurface({
    required this.color,
    required this.child,
    this.lightweight = false,
    super.key,
  });

  final Color color;
  final Widget child;
  final bool lightweight;

  @override
  Widget build(BuildContext context) {
    if (NotebookVisuals.maybeOf(context) == null) {
      return ColoredBox(color: color, child: child);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage(NotebookAssets.leather),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          colorFilter: ColorFilter.mode(
            color.withValues(alpha: 0.55),
            BlendMode.srcATop,
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: lightweight ? 0.12 : 0.24),
              Colors.transparent,
              Colors.black.withValues(alpha: lightweight ? 0.1 : 0.22),
            ],
            stops: const [0, 0.4, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}

Color notebookLeatherForeground(Color color) {
  final tintedLeather = Color.alphaBlend(
    color.withValues(alpha: 0.55),
    const Color(0xFFF3EFE6),
  );
  return ThemeData.estimateBrightnessForColor(tintedLeather) == Brightness.dark
      ? Colors.white
      : const Color(0xFF24160E);
}
