import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../themes/notebook/notebook_assets.dart';
import '../../themes/notebook/notebook_background.dart';
import '../../themes/notebook/notebook_visuals.dart';
import '../../themes/surface_palette.dart';
import '../../themes/surface_textures.dart';
import 'page_turn_geometry.dart';

@immutable
class PagePaperStyle {
  const PagePaperStyle({
    required this.paperColor,
    required this.frontFallback,
    required this.shadowColor,
    required this.textureAsset,
    required this.textureOpacity,
    required this.backLineColor,
  });

  final Color paperColor;
  final Color frontFallback;
  final Color shadowColor;
  final String? textureAsset;
  final double textureOpacity;
  final Color? backLineColor;

  factory PagePaperStyle.of(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
    final palette = AppSurfacePalette.of(context);
    return PagePaperStyle(
      paperColor: notebook?.paper ?? palette.panelSurface,
      frontFallback: palette.backgroundStart,
      shadowColor: Colors.black.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.52 : 0.36,
      ),
      textureAsset:
          notebook != null ? NotebookAssets.paper : textures?.surfaceAsset,
      textureOpacity: notebook != null ? 0.62 : textures?.surfaceOpacity ?? 0,
      backLineColor: notebook?.line,
    );
  }
}

class PageTurnPainter extends CustomPainter {
  PageTurnPainter({
    required this.image,
    required this.paperTexture,
    required this.animation,
    this.reverseProgress = false,
    required PagePaperStyle paperStyle,
  })  : _paperColor = paperStyle.paperColor,
        _frontFallback = paperStyle.frontFallback,
        _shadowColor = paperStyle.shadowColor,
        _textureOpacity = paperStyle.textureOpacity,
        _backLineColor = paperStyle.backLineColor,
        super(repaint: animation) {
    _snapshotPaint.filterQuality = FilterQuality.medium;
    _frontTexturePaint
      ..shader = _imageShader(image)
      ..filterQuality = FilterQuality.medium;
    final backTexture = paperTexture;
    if (backTexture != null) {
      _backTexturePaint
        ..shader = _imageShader(backTexture)
        ..filterQuality = FilterQuality.medium;
    }
  }

  final ui.Image image;
  final ui.Image? paperTexture;
  final Animation<double> animation;
  final bool reverseProgress;
  final Color _paperColor;
  final Color _frontFallback;
  final Color _shadowColor;
  final double _textureOpacity;
  final Color? _backLineColor;

  final Paint _snapshotPaint = Paint();
  final Paint _foldShadowPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _freeEdgeShadowPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _cellPaint = Paint()..isAntiAlias = false;
  final Paint _backLinePaint = Paint()..strokeWidth = 1;
  final Paint _frontTexturePaint = Paint();
  final Paint _backTexturePaint = Paint();
  final Paint _highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.28)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
  final Paint _edgeDarkPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.22)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  final Paint _edgeLightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.34)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  final Path _foldShadowPath = Path();
  final Path _backLinesPath = Path();
  final Path _highlightPath = Path();
  final Path _edgePathBuffer = Path();
  PageTurnMesh? _mesh;
  final PageTurnCellVertices _cellVertices = PageTurnCellVertices();

  static const double _focalLength = 900;
  static final Float64List _identityMatrix = Float64List.fromList(const [
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);

  static ui.ImageShader _imageShader(ui.Image image) {
    return ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      _identityMatrix,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final easedProgress = Curves.easeInOutCubic.transform(animation.value);
    final normalizedProgress =
        (reverseProgress ? 1 - easedProgress : easedProgress).clamp(0.0, 1.0);
    if (normalizedProgress <= 0.0001) {
      canvas.drawColor(_frontFallback, BlendMode.src);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Offset.zero & size,
        _snapshotPaint,
      );
      return;
    }
    if (normalizedProgress >= 0.9999) return;

    final geometry = PageTurnGeometry(
      width: size.width,
      progress: normalizedProgress,
    );
    final columns = (size.width / 8).ceil().clamp(48, 72);
    final rows = (size.height / 240).ceil().clamp(3, 5);
    final mesh = _meshFor(size, columns, rows);
    final projected = mesh.projected;
    for (var column = 0; column <= columns; column++) {
      final materialX = size.width * column / columns;
      for (var row = 0; row <= rows; row++) {
        final verticalT = row / rows;
        final materialY = size.height * verticalT;
        _updateProjectedVertex(
          projected[column][row],
          geometry.project(materialX, verticalT: verticalT),
          materialX,
          materialY,
          size,
        );
      }
    }

    _paintFoldShadow(canvas, size, geometry);
    _paintFreeEdgeShadow(canvas, projected.last, geometry.motionEnvelope);

    final cells = mesh.cells;
    for (final cell in cells) {
      cell.updatePath();
    }
    cells.sort((a, b) => a.averageDepth.compareTo(b.averageDepth));

    _paintOpaqueSilhouette(canvas, cells);
    _paintCells(canvas, size, cells);
    _paintCurlHighlight(canvas, size, geometry);
    _paintFreeEdge(canvas, projected.last);
  }

  PageTurnMesh _meshFor(Size size, int columns, int rows) {
    final current = _mesh;
    if (current != null && current.matches(size, columns, rows)) return current;
    return _mesh = PageTurnMesh(size: size, columns: columns, rows: rows);
  }

  void _updateProjectedVertex(
    ProjectedVertex target,
    PageTurnGeometryPoint point,
    double materialX,
    double materialY,
    Size size,
  ) {
    target.update(
      offset: _projectOffset(point, materialY, size),
      materialX: materialX,
      materialY: materialY,
      depth: point.depth,
      angle: point.angle,
    );
  }

  Offset _projectOffset(
    PageTurnGeometryPoint point,
    double materialY,
    Size size,
  ) {
    final focalLength = math.max(_focalLength, size.longestSide * 1.35);
    final perspective = focalLength / (focalLength - point.depth);
    return Offset(
      point.x * perspective,
      size.height / 2 + (materialY - size.height / 2) * perspective,
    );
  }

  void _paintFoldShadow(Canvas canvas, Size size, PageTurnGeometry geometry) {
    final strength = geometry.motionEnvelope;
    if (strength <= 0.001) return;
    final path = _foldShadowPath..reset();
    for (var sample = 0; sample <= 8; sample++) {
      final verticalT = sample / 8;
      final point = Offset(
        geometry.foldXAt(verticalT) + geometry.radiusAt(verticalT) * 0.18,
        size.height * verticalT,
      );
      if (sample == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final radius = geometry.radius;
    _foldShadowPaint
      ..color = _shadowColor.withValues(
        alpha: _shadowColor.a * 0.42 * strength,
      )
      ..strokeWidth = (radius * 0.62).clamp(16.0, 38.0)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        (radius * 0.32).clamp(6.0, 18.0),
      );
    canvas.drawPath(path, _foldShadowPaint);
  }

  void _paintFreeEdgeShadow(
    Canvas canvas,
    List<ProjectedVertex> edge,
    double strength,
  ) {
    if (strength <= 0.001) return;
    final path = _updateEdgePath(edge);
    _freeEdgeShadowPaint
      ..color = _shadowColor.withValues(
        alpha: _shadowColor.a * 0.5 * strength,
      )
      ..strokeWidth = 10 + 8 * strength
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 + 5 * strength);
    canvas.drawPath(path, _freeEdgeShadowPaint);
  }

  void _paintOpaqueSilhouette(
    Canvas canvas,
    List<ProjectedCell> cells,
  ) {
    _cellPaint.color = _paperColor;
    for (final cell in cells) {
      // Independent paths keep reversed folds opaque without relying on a
      // combined Path's winding rule.
      canvas.drawPath(cell.path, _cellPaint);
    }
  }

  void _paintCells(
    Canvas canvas,
    Size size,
    List<ProjectedCell> cells,
  ) {
    for (final cell in cells) {
      _paintCell(canvas, size, cell);
    }
  }

  void _paintCell(Canvas canvas, Size size, ProjectedCell cell) {
    final isBack = cell.averageAngle > math.pi / 2;
    final light = pageTurnLight(cell.averageAngle, isBack: isBack);
    _cellPaint.color = Color.lerp(
      Colors.black,
      isBack ? _paperColor : _frontFallback,
      light,
    )!;
    canvas.drawPath(cell.path, _cellPaint);

    if (isBack) {
      final texture = paperTexture;
      if (texture != null && _textureOpacity > 0) {
        _drawTexturedCell(
          canvas,
          cell,
          texture,
          size,
          paint: _backTexturePaint,
          opacity: _textureOpacity,
          mirrorX: true,
          isBack: true,
        );
      }
      _paintBackLines(
        canvas,
        cell,
        light,
      );
      return;
    }

    _drawTexturedCell(
      canvas,
      cell,
      image,
      size,
      paint: _frontTexturePaint,
      opacity: 1,
      mirrorX: false,
      isBack: false,
    );
  }

  void _drawTexturedCell(
    Canvas canvas,
    ProjectedCell cell,
    ui.Image texture,
    Size size, {
    required Paint paint,
    required double opacity,
    required bool mirrorX,
    required bool isBack,
  }) {
    _cellVertices.update(
      cell,
      size: size,
      texture: texture,
      opacity: opacity,
      mirrorX: mirrorX,
      isBack: isBack,
    );
    canvas.drawVertices(
      _cellVertices.toVertices(),
      BlendMode.modulate,
      paint,
    );
  }

  void _paintBackLines(
    Canvas canvas,
    ProjectedCell cell,
    double light,
  ) {
    final lineColor = _backLineColor;
    if (lineColor == null) return;

    final litColor = Color.lerp(
      Colors.black,
      lineColor.withValues(alpha: 1),
      light,
    )!
        .withValues(alpha: lineColor.a);
    _backLinePaint.color = litColor;

    final topY = cell.topLeft.materialY;
    final bottomY = cell.bottomLeft.materialY;
    var materialY = notebookPageLineTop;
    if (materialY < topY) {
      materialY += ((topY - materialY) / notebookPageLineHeight).ceil() *
          notebookPageLineHeight;
    }
    final lines = _backLinesPath..reset();
    while (materialY <= bottomY + 0.001) {
      final verticalT = (materialY - topY) / (bottomY - topY);
      final left = Offset.lerp(
        cell.topLeft.offset,
        cell.bottomLeft.offset,
        verticalT,
      )!;
      final right = Offset.lerp(
        cell.topRight.offset,
        cell.bottomRight.offset,
        verticalT,
      )!;
      lines.moveTo(left.dx, left.dy);
      lines.lineTo(right.dx, right.dy);
      materialY += notebookPageLineHeight;
    }

    canvas.save();
    canvas.clipPath(cell.path);
    canvas.drawPath(lines, _backLinePaint);
    canvas.restore();
  }

  void _paintCurlHighlight(
    Canvas canvas,
    Size size,
    PageTurnGeometry geometry,
  ) {
    final highlight = _highlightPath..reset();
    var started = false;
    for (var sample = 0; sample <= 12; sample++) {
      final verticalT = sample / 12;
      final radius = geometry.radiusAt(verticalT);
      final materialX = geometry.foldXAt(verticalT) + math.pi * radius / 2;
      if (materialX <= 0 || materialX >= size.width) {
        started = false;
        continue;
      }
      final offset = _projectOffset(
        geometry.project(materialX, verticalT: verticalT),
        size.height * verticalT,
        size,
      );
      if (!started) {
        highlight.moveTo(offset.dx, offset.dy);
        started = true;
      } else {
        highlight.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(highlight, _highlightPaint);
  }

  void _paintFreeEdge(Canvas canvas, List<ProjectedVertex> edge) {
    final path = _updateEdgePath(edge);
    canvas.drawPath(path, _edgeDarkPaint);
    canvas.drawPath(path, _edgeLightPaint);
  }

  Path _updateEdgePath(List<ProjectedVertex> edge) {
    final path = _edgePathBuffer..reset();
    for (var index = 0; index < edge.length; index++) {
      final point = edge[index].offset;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(PageTurnPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.paperTexture != paperTexture ||
        oldDelegate.animation != animation ||
        oldDelegate.reverseProgress != reverseProgress ||
        oldDelegate._paperColor != _paperColor ||
        oldDelegate._frontFallback != _frontFallback ||
        oldDelegate._shadowColor != _shadowColor ||
        oldDelegate._textureOpacity != _textureOpacity ||
        oldDelegate._backLineColor != _backLineColor;
  }
}
