import 'package:flutter/material.dart';

import '../themes/screen/glass_surface.dart';
import '../themes/screen/screen_theme_colors.dart';
import 'screen_glass_surface_painter.dart';

/// A thick translucent plate with a clear concave centre and refracted edges.
class ScreenGlassSurface extends StatelessWidget {
  const ScreenGlassSurface({
    required this.colors,
    required this.opacity,
    required this.child,
    this.tint,
    this.pressed = false,
    this.illuminated = false,
    this.showShadow = true,
    this.painterKey,
    this.lampKey,
    super.key,
  });

  final ScreenThemeColors colors;
  final double opacity;
  final Color? tint;
  final bool pressed;
  final bool illuminated;
  final bool showShadow;
  final Key? painterKey;
  final Key? lampKey;
  final Widget child;

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final density =
        (opacity + (colors.isDark ? 0.08 : 0)).clamp(0.0, 0.82).toDouble();
    final back = (tint ?? colors.panel).withValues(alpha: density);
    final lampCore = Color.alphaBlend(
      colors.accent.withValues(alpha: 0.48),
      colors.glint,
    );
    return AnimatedScale(
      scale: pressed ? 0.965 : 1,
      duration: pressed ? Duration.zero : const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: pressed ? Duration.zero : const Duration(milliseconds: 110),
        transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          gradient: GlassSurface.gradient(colors, back),
          borderRadius: _radius,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: pressed ? 0.12 : (colors.isDark ? 0.42 : 0.18),
                    ),
                    blurRadius: pressed ? 3 : 9,
                    offset: Offset(0, pressed ? 1 : 4),
                  ),
                  BoxShadow(
                    color:
                        colors.accent.withValues(alpha: illuminated ? 0.72 : 0),
                    blurRadius: illuminated ? 16 : 0,
                    spreadRadius: illuminated ? 0.8 : 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: CustomPaint(
            key: painterKey,
            foregroundPainter: ScreenGlassSurfacePainter(
              colors: colors,
              pressed: pressed,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    key: lampKey,
                    opacity: illuminated ? 1 : 0,
                    duration: illuminated
                        ? Duration.zero
                        : const Duration(milliseconds: 140),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.82,
                          colors: [
                            lampCore.withValues(alpha: 0.96),
                            colors.glint.withValues(alpha: 0.82),
                            colors.accent.withValues(alpha: 0.76),
                            colors.accent.withValues(alpha: 0.24),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.18, 0.46, 0.72, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
