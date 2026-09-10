import 'package:flutter/material.dart';

import '../themes/screen/screen_theme_colors.dart';

enum ScreenGlassProfile { concave, convex }

/// Refraction inside a thick glass surface.
///
/// The outer bevel catches light from above-left. The inset bevel reverses
/// that light, so the broad middle reads as a hollow rather than a bubble.
class ScreenGlassSurfacePainter extends CustomPainter {
  const ScreenGlassSurfacePainter({
    required this.colors,
    required this.pressed,
    this.profile = ScreenGlassProfile.concave,
    this.showOuterEdge = true,
    this.radius = 8,
  });

  final ScreenThemeColors colors;
  final bool pressed;
  final ScreenGlassProfile profile;
  final bool showOuterEdge;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      bounds.deflate(0.6),
      Radius.circular((radius - 0.6).clamp(0, radius)),
    );
    final refraction = RRect.fromRectAndRadius(
      bounds.deflate(2.2),
      Radius.circular((radius - 1.8).clamp(0, radius)),
    );
    final hollow = RRect.fromRectAndRadius(
      bounds.deflate(4.2),
      Radius.circular((radius - 2.8).clamp(0, radius)),
    );

    if (showOuterEdge) {
      canvas.drawRRect(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.glint.withValues(alpha: 0.96),
              colors.glint.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: colors.isDark ? 0.42 : 0.24),
            ],
            stops: const [0, 0.48, 1],
          ).createShader(bounds),
      );
    }
    canvas.drawRRect(
      refraction,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..shader = SweepGradient(
          colors: [
            colors.glint.withValues(alpha: 0.68),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
            colors.glint.withValues(alpha: 0.68),
          ],
        ).createShader(bounds),
    );
    if (profile == ScreenGlassProfile.convex) {
      _paintConvexLens(canvas, hollow);
    } else {
      _paintConcaveLens(canvas, hollow);
    }
    _paintStreetLightReflections(canvas, bounds, hollow);
    canvas.drawRRect(
      hollow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = profile == ScreenGlassProfile.convex
            ? (pressed ? 3.0 : 2.2)
            : (pressed ? 3.6 : 2.8)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: profile == ScreenGlassProfile.convex
              ? [
                  colors.glint.withValues(alpha: pressed ? 0.98 : 0.82),
                  Colors.transparent,
                  Colors.black.withValues(
                    alpha: colors.isDark ? 0.46 : 0.28,
                  ),
                ]
              : [
                  Colors.black.withValues(
                    alpha: pressed
                        ? (colors.isDark ? 0.62 : 0.42)
                        : (colors.isDark ? 0.34 : 0.22),
                  ),
                  Colors.transparent,
                  colors.glint.withValues(alpha: pressed ? 0.98 : 0.78),
                ],
          stops: const [0, 0.48, 1],
        ).createShader(hollow.outerRect),
    );
  }

  void _paintConcaveLens(Canvas canvas, RRect hollow) {
    canvas.drawRRect(
      hollow,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.08),
          radius: 0.92,
          colors: [
            Colors.transparent,
            colors.glint.withValues(alpha: pressed ? 0.28 : 0.05),
            Colors.black.withValues(
              alpha: pressed
                  ? (colors.isDark ? 0.34 : 0.20)
                  : (colors.isDark ? 0.20 : 0.11),
            ),
          ],
          stops: const [0, 0.62, 1],
        ).createShader(hollow.outerRect),
    );
  }

  void _paintConvexLens(Canvas canvas, RRect lens) {
    final rect = lens.outerRect;
    canvas.drawRRect(
      lens,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.24, -0.30),
          radius: 1.12,
          colors: [
            colors.glint.withValues(alpha: colors.isDark ? 0.22 : 0.15),
            colors.glint.withValues(alpha: colors.isDark ? 0.09 : 0.05),
            Colors.transparent,
            Colors.black.withValues(alpha: colors.isDark ? 0.24 : 0.12),
          ],
          stops: const [0, 0.28, 0.64, 1],
        ).createShader(rect),
    );

    final highlight = Rect.fromCenter(
      center: Offset(
        rect.left + rect.width * 0.30,
        rect.top + rect.height * 0.24,
      ),
      width: rect.width * 0.48,
      height: rect.height * 0.18,
    );
    canvas.drawOval(
      highlight,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colors.glint.withValues(alpha: colors.isDark ? 0.24 : 0.18),
            Colors.transparent,
          ],
        ).createShader(highlight),
    );
  }

  void _paintStreetLightReflections(
    Canvas canvas,
    Rect bounds,
    RRect hollow,
  ) {
    final lights = colors.glassLights;
    if (lights.isEmpty) return;
    final cyan = lights.first;
    final magenta = lights.length > 1 ? lights[1] : colors.accent;
    final green = lights.length > 2 ? lights[2] : colors.glint;

    canvas.save();
    canvas.clipRRect(hollow);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -0.65),
          end: const Alignment(1, 0.65),
          colors: [
            cyan.withValues(alpha: 0.16),
            Colors.transparent,
            magenta.withValues(alpha: pressed ? 0.2 : 0.13),
            Colors.transparent,
            green.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0, 0.2, 0.46, 0.64, 0.84, 1],
        ).createShader(bounds),
    );

    final streak = Rect.fromLTWH(
      bounds.left + bounds.width * 0.3,
      bounds.top - bounds.height * 0.2,
      bounds.width * 0.16,
      bounds.height * 1.4,
    );
    canvas.drawRect(
      streak,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            magenta.withValues(alpha: pressed ? 0.2 : 0.1),
            Colors.transparent,
          ],
        ).createShader(streak),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScreenGlassSurfacePainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.pressed != pressed ||
      oldDelegate.profile != profile ||
      oldDelegate.showOuterEdge != showOuterEdge ||
      oldDelegate.radius != radius;
}
