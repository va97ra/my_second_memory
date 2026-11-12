import 'package:flutter/material.dart';

import '../surface_palette.dart';
import '../surface_textures.dart';
import 'notebook_leather_surface.dart';
import 'notebook_visuals.dart';

const double notebookPageLineTop = 34;
const double notebookPageLineHeight = 28;

DecorationImage _pageTexture(NotebookVisuals notebook) {
  final scale = notebook.paperGrainScale;
  return DecorationImage(
    image: AssetImage(notebook.paperAsset),
    fit: scale == null ? BoxFit.cover : BoxFit.none,
    repeat: scale == null ? ImageRepeat.noRepeat : ImageRepeat.repeat,
    scale: scale ?? 1,
    opacity: 0.62,
    filterQuality: FilterQuality.low,
  );
}

/// Бумага страницы без разлиновки: цвет, текстура, и больше ничего.
///
/// Выделено отдельно, потому что нужно в двух местах: общий фон кладёт поверх
/// неё линейки, а шкала дня — свои часовые линии, и линейки страницы там
/// лишние. Без этого пришлось бы держать вторую копию рисования фона.
class NotebookPaperFill extends StatelessWidget {
  const NotebookPaperFill({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    if (notebook != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: notebook.paper,
          image: _pageTexture(notebook),
        ),
        child: child,
      );
    }
    final palette = AppSurfacePalette.of(context);
    return DecoratedBox(
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
      child: child,
    );
  }
}

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: NotebookPaperFill(
            child: notebook == null
                ? const SizedBox.expand()
                : CustomPaint(
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
        image: _pageTexture(notebook),
        borderRadius: BorderRadius.circular(8),
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
    this.scroll,
  }) : super(repaint: scroll);

  final Color color;
  final double top;
  final double lineHeight;

  /// Прокрутка текста на этом листе: линейка едет вместе с текстом, как на
  /// настоящей бумаге, и строки остаются на своих линиях.
  final ScrollController? scroll;

  /// Где сейчас первая линейка на видимой части листа.
  double get firstLine {
    final position = scroll;
    final offset =
        position != null && position.hasClients ? position.offset : 0.0;
    var y = top - offset;
    if (y < 0) y += ((-y / lineHeight).floor() + 1) * lineHeight;
    return y;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!lineHeight.isFinite || lineHeight <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double y = firstLine; y < size.height; y += lineHeight) {
      canvas.drawLine(
          Offset.zero.translate(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NotebookPaperLinesPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.top != top ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.scroll != scroll;
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

/// Карточка лежит на коже страницы и выделяется на ней дважды: кожа светлее
/// (уровень «карточка» из темы) и поры мельче, чем на фоне.
/// Во сколько раз поры карточки мельче снимка кожи.
const double _cardGrainScale = 4;

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
    final surfaceColor = color ?? Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: notebookSurfaceShadow(context, depth),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: NotebookLeatherSurface(
          color: surfaceColor,
          lightweight: true,
          grainScale: _cardGrainScale,
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
      ),
    );
  }
}
