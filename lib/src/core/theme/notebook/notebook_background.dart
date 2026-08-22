import 'package:flutter/material.dart';

import '../app_surface_palette.dart';
import '../app_surface_textures.dart';
import 'notebook_leather_surface.dart';
import 'notebook_visuals.dart';

const double notebookPageLineTop = 34;
const double notebookPageLineHeight = 28;

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final palette = AppSurfacePalette.of(context);
    if (notebook == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: palette.backgroundGradient,
                image: switch (AppSurfaceTextures.maybeOf(context)) {
                  null => null,
                  final textures => DecorationImage(
                      image: AssetImage(textures.backgroundAsset),
                      fit: BoxFit.cover,
                      opacity: textures.backgroundOpacity,
                      filterQuality: FilterQuality.low,
                    ),
                },
              ),
            ),
          ),
          RepaintBoundary(child: child),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: notebook.paper,
              image: DecorationImage(
                image: AssetImage(notebook.paperAsset),
                fit: BoxFit.cover,
                opacity: 0.62,
                filterQuality: FilterQuality.low,
              ),
            ),
            child: CustomPaint(
              painter: NotebookPaperLinesPainter(
                color: notebook.line,
                top: notebookPageLineTop,
                lineHeight: notebookPageLineHeight,
              ),
            ),
          ),
        ),
        RepaintBoundary(child: child),
      ],
    );
  }
}

class NotebookPageSurface extends StatelessWidget {
  const NotebookPageSurface({
    required this.child,
    this.showLines = false,
    this.lineTop = notebookPageLineTop,
    this.lineHeight = notebookPageLineHeight,
    this.padding,
    super.key,
  });

  final Widget child;
  final bool showLines;
  final double lineTop;
  final double lineHeight;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
    if (notebook == null) {
      if (textures == null) {
        return Padding(padding: padding ?? EdgeInsets.zero, child: child);
      }
      final palette = AppSurfacePalette.of(context);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: palette.surfaceGradient(),
          image: DecorationImage(
            image: AssetImage(textures.surfaceAsset),
            fit: BoxFit.cover,
            opacity: textures.surfaceOpacity,
            filterQuality: FilterQuality.low,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.borderStart),
          boxShadow: notebookSurfaceShadow(
            context,
            NotebookSurfaceDepth.panel,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: showLines
                ? NotebookPaperLinesPainter(
                    color: textures.lineColor,
                    top: lineTop,
                    lineHeight: lineHeight,
                  )
                : null,
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: notebook.paper,
        image: DecorationImage(
          image: AssetImage(notebook.paperAsset),
          fit: BoxFit.cover,
          opacity: 0.62,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB97742)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: showLines
              ? NotebookPaperLinesPainter(
                  color: notebook.line,
                  top: lineTop,
                  lineHeight: lineHeight,
                )
              : null,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

class NotebookPaperLinesPainter extends CustomPainter {
  const NotebookPaperLinesPainter({
    required this.color,
    required this.top,
    required this.lineHeight,
  });

  final Color color;
  final double top;
  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (!lineHeight.isFinite || lineHeight <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double y = top; y < size.height; y += lineHeight) {
      canvas.drawLine(
          Offset.zero.translate(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NotebookPaperLinesPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.top != top ||
        oldDelegate.lineHeight != lineHeight;
  }
}

enum NotebookSurfaceDepth { tile, card, panel }

List<BoxShadow> notebookSurfaceShadow(
  BuildContext context,
  NotebookSurfaceDepth depth,
) {
  if (NotebookVisuals.maybeOf(context) == null &&
      AppSurfaceTextures.maybeOf(context) == null) {
    return const [];
  }
  final offset = switch (depth) {
    NotebookSurfaceDepth.tile => 2.0,
    NotebookSurfaceDepth.card => 4.0,
    NotebookSurfaceDepth.panel => 6.0,
  };
  return [
    BoxShadow(
      color: const Color(0x66000000),
      blurRadius: offset + 4,
      offset: Offset(0, offset),
    ),
    const BoxShadow(
      color: Color(0x55FFFFFF),
      blurRadius: 0,
      offset: Offset(0, -1),
    ),
  ];
}

/// What a surface is made of: a sheet of the notebook, or its cover.
enum NotebookSurfaceMaterial { paper, leather }

class NotebookCardSurface extends StatelessWidget {
  const NotebookCardSurface({
    required this.child,
    this.depth = NotebookSurfaceDepth.card,
    this.material = NotebookSurfaceMaterial.paper,
    this.showLines = false,
    this.lineTop = 24,
    this.lineHeight = 24,
    this.padding,
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final NotebookSurfaceDepth depth;
  final NotebookSurfaceMaterial material;
  final bool showLines;
  final double lineTop;
  final double lineHeight;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
    if (notebook == null) {
      if (textures == null) {
        return Padding(padding: padding ?? EdgeInsets.zero, child: child);
      }
      final palette = AppSurfacePalette.of(context);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: palette.surfaceGradient(
            base: color ?? palette.panelSurface,
          ),
          image: DecorationImage(
            image: AssetImage(textures.surfaceAsset),
            fit: BoxFit.cover,
            opacity: textures.surfaceOpacity,
            filterQuality: FilterQuality.low,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor ?? palette.borderStart),
          boxShadow: notebookSurfaceShadow(context, depth),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: showLines
                ? NotebookPaperLinesPainter(
                    color: textures.lineColor,
                    top: lineTop,
                    lineHeight: lineHeight,
                  )
                : null,
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      );
    }
    final surfaceColor = color ?? notebook.paper;
    final lined = CustomPaint(
      painter: showLines
          ? NotebookPaperLinesPainter(
              color: notebook.line,
              top: lineTop,
              lineHeight: lineHeight,
            )
          : null,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        // Paper grain is laid on directly; leather comes through the same
        // surface the navigation panel wears, so the two materials match.
        image: material == NotebookSurfaceMaterial.paper
            ? DecorationImage(
                image: AssetImage(notebook.paperAsset),
                fit: BoxFit.cover,
                opacity: 0.52,
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? const Color(0xFFB97742)),
        boxShadow: notebookSurfaceShadow(context, depth),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: material == NotebookSurfaceMaterial.paper
            ? lined
            : NotebookLeatherSurface(
                color: surfaceColor,
                lightweight: true,
                child: lined,
              ),
      ),
    );
  }
}
