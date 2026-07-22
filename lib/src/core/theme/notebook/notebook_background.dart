import 'package:flutter/material.dart';

import '../app_surface_palette.dart';
import 'notebook_assets.dart';
import 'notebook_visuals.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final palette = AppSurfacePalette.of(context);
    if (notebook == null) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backgroundGradient),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC98D57), Color(0xFF96572F)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            NotebookAssets.wood,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          ColoredBox(color: const Color(0xFF4B2410).withValues(alpha: 0.08)),
          child,
        ],
      ),
    );
  }
}

class NotebookPageSurface extends StatelessWidget {
  const NotebookPageSurface({
    required this.child,
    this.showLines = false,
    this.lineTop = 34,
    this.lineHeight = 28,
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
    if (notebook == null) {
      return Padding(padding: padding ?? EdgeInsets.zero, child: child);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: notebook.paper,
        image: const DecorationImage(
          image: AssetImage(NotebookAssets.paper),
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
  if (NotebookVisuals.maybeOf(context) == null) return const [];
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

class NotebookCardSurface extends StatelessWidget {
  const NotebookCardSurface({
    required this.child,
    this.depth = NotebookSurfaceDepth.card,
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
  final bool showLines;
  final double lineTop;
  final double lineHeight;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    if (notebook == null) {
      return Padding(padding: padding ?? EdgeInsets.zero, child: child);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? notebook.paper,
        image: const DecorationImage(
          image: AssetImage(NotebookAssets.paper),
          fit: BoxFit.cover,
          opacity: 0.52,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? const Color(0xFFB97742)),
        boxShadow: notebookSurfaceShadow(context, depth),
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
