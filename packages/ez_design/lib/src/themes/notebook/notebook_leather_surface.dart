import '../../tokens/app_palette.dart';
import 'package:flutter/material.dart';

import '../surface_palette.dart';
import '../surface_textures.dart';
import 'notebook_visuals.dart';

class NotebookLeatherSurface extends StatelessWidget {
  const NotebookLeatherSurface({
    required this.color,
    required this.child,
    this.lightweight = false,
    this.grainScale,
    super.key,
  });

  final Color color;
  final Widget child;
  final bool lightweight;

  /// Мельче ли поры, чем на снимке кожи: кожа кладётся плиткой и не зависит от
  /// размера поверхности. Без него снимок растянут на всю поверхность.
  final double? grainScale;

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
        // The opaque fallback belongs to the same paint layer as the asset.
        // Keeping it in a separate widget lets the compositor expose whatever
        // sits under the texture for one frame while the image layer is being
        // reallocated (most visibly during shell navigation).
        color: color,
        image: DecorationImage(
          image: AssetImage(
            notebook == null ? textures!.accentAsset : notebook.leatherAsset,
          ),
          fit: grainScale == null ? BoxFit.cover : BoxFit.none,
          repeat:
              grainScale == null ? ImageRepeat.noRepeat : ImageRepeat.repeat,
          scale: grainScale ?? 1,
          filterQuality:
              grainScale == null ? FilterQuality.low : FilterQuality.medium,
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
    AppPalette.paper,
  );
  return ThemeData.estimateBrightnessForColor(tintedLeather) == Brightness.dark
      ? Colors.white
      : AppPalette.paperInk;
}
