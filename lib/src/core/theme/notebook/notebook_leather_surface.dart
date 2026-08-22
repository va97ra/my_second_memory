import 'package:flutter/material.dart';

import '../app_surface_palette.dart';
import '../app_surface_textures.dart';
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
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
    final isLightAppTheme = notebook == null &&
        textures != null &&
        Theme.of(context).brightness == Brightness.light;
    if (notebook == null && textures == null) {
      final palette = AppSurfacePalette.of(context);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.22)!,
              color,
              Color.lerp(color, palette.accentEnd, 0.18)!,
              Color.lerp(color, Colors.black, 0.18)!,
            ],
            stops: const [0, 0.28, 0.72, 1],
          ),
        ),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: notebook == null ? color : null,
        image: DecorationImage(
          image: AssetImage(
            notebook == null ? textures!.accentAsset : notebook.leatherAsset,
          ),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          opacity: notebook == null ? textures!.accentOpacity : 1,
          colorFilter: ColorFilter.mode(
            color.withValues(
              alpha: notebook == null
                  ? isLightAppTheme
                      ? 0.82
                      : 0.72
                  : 0.55,
            ),
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
              Colors.white.withValues(
                alpha: lightweight
                    ? 0.12
                    : isLightAppTheme
                        ? 0.1
                        : 0.24,
              ),
              Colors.transparent,
              Colors.black.withValues(
                alpha: lightweight
                    ? 0.1
                    : isLightAppTheme
                        ? 0.16
                        : 0.22,
              ),
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
