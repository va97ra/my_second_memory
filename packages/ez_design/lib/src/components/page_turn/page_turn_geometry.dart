import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

class PageTurnGeometry {
  const PageTurnGeometry({required this.width, required this.progress});

  final double width;
  final double progress;

  double get normalizedProgress => progress.clamp(0.0, 1.0);

  double get motionEnvelope => math.sin(math.pi * normalizedProgress);

  double get radius => radiusAt(0.5);

  double radiusAt(double verticalT) {
    final t = verticalT.clamp(0.0, 1.0);
    final breathingRadius = width * (0.065 + 0.055 * motionEnvelope);
    final verticalVariation =
        1 + 0.07 * math.sin(math.pi * 2 * t) * motionEnvelope;
    return breathingRadius.clamp(22.0, 60.0) * verticalVariation;
  }

  double get foldX => foldXAt(0.5);

  double foldXAt(double verticalT) {
    final t = verticalT.clamp(0.0, 1.0);
    final localRadius = radiusAt(t);
    final baseFold = ui.lerpDouble(
      width,
      -math.pi * localRadius,
      normalizedProgress,
    )!;
    final foldAmplitude = (width * 0.038).clamp(8.0, 20.0) * motionEnvelope;
    final foldWave =
        0.72 * math.sin(math.pi * (t - 0.5)) + 0.28 * math.sin(math.pi * 2 * t);
    return baseFold + foldAmplitude * foldWave;
  }

  PageTurnGeometryPoint project(
    double materialX, {
    double verticalT = 0.5,
  }) {
    final localRadius = radiusAt(verticalT);
    final localFoldX = foldXAt(verticalT);
    final distance = materialX - localFoldX;
    if (distance <= 0) {
      return PageTurnGeometryPoint(x: materialX, depth: 0, angle: 0);
    }

    final curlLength = math.pi * localRadius;
    if (distance < curlLength) {
      final angle = distance / localRadius;
      return PageTurnGeometryPoint(
        x: localFoldX + localRadius * math.sin(angle),
        depth: localRadius * (1 - math.cos(angle)),
        angle: angle,
      );
    }

    return PageTurnGeometryPoint(
      x: localFoldX - (distance - curlLength),
      depth: localRadius * 2,
      angle: math.pi,
    );
  }
}

class PageTurnGeometryPoint {
  const PageTurnGeometryPoint({
    required this.x,
    required this.depth,
    required this.angle,
  });

  final double x;
  final double depth;
  final double angle;
}

class PageTurnMesh {
  PageTurnMesh({
    required this.size,
    required this.columns,
    required this.rows,
  }) : projected = List.generate(
          columns + 1,
          (column) => List.generate(
            rows + 1,
            (row) => ProjectedVertex(
              materialX: size.width * column / columns,
              materialY: size.height * row / rows,
            ),
            growable: false,
          ),
          growable: false,
        ) {
    cells = <ProjectedCell>[
      for (var column = 0; column < columns; column++)
        for (var row = 0; row < rows; row++)
          ProjectedCell(
            topLeft: projected[column][row],
            bottomLeft: projected[column][row + 1],
            topRight: projected[column + 1][row],
            bottomRight: projected[column + 1][row + 1],
          ),
    ];
  }

  final Size size;
  final int columns;
  final int rows;
  final List<List<ProjectedVertex>> projected;
  late final List<ProjectedCell> cells;

  bool matches(Size otherSize, int otherColumns, int otherRows) {
    return size == otherSize && columns == otherColumns && rows == otherRows;
  }
}

class ProjectedVertex {
  ProjectedVertex({
    required this.materialX,
    required this.materialY,
  })  : offset = Offset.zero,
        depth = 0,
        angle = 0;

  Offset offset;
  double materialX;
  double materialY;
  double depth;
  double angle;

  void update({
    required Offset offset,
    required double materialX,
    required double materialY,
    required double depth,
    required double angle,
  }) {
    this.offset = offset;
    this.materialX = materialX;
    this.materialY = materialY;
    this.depth = depth;
    this.angle = angle;
  }
}

class ProjectedCell {
  ProjectedCell({
    required this.topLeft,
    required this.bottomLeft,
    required this.topRight,
    required this.bottomRight,
  }) : vertices = [topLeft, bottomLeft, topRight, bottomRight];

  final ProjectedVertex topLeft;
  final ProjectedVertex bottomLeft;
  final ProjectedVertex topRight;
  final ProjectedVertex bottomRight;
  final List<ProjectedVertex> vertices;
  final Path path = Path();

  void updatePath() {
    path
      ..reset()
      ..moveTo(topLeft.offset.dx, topLeft.offset.dy)
      ..lineTo(bottomLeft.offset.dx, bottomLeft.offset.dy)
      ..lineTo(bottomRight.offset.dx, bottomRight.offset.dy)
      ..lineTo(topRight.offset.dx, topRight.offset.dy)
      ..close();
  }

  double get averageDepth =>
      (topLeft.depth + bottomLeft.depth + topRight.depth + bottomRight.depth) /
      4;

  double get averageAngle =>
      (topLeft.angle + bottomLeft.angle + topRight.angle + bottomRight.angle) /
      4;
}

class PageTurnCellVertices {
  final Float32List _positions = Float32List(8);
  final Float32List _textureCoordinates = Float32List(8);
  final Int32List _colors = Int32List(4);
  final Uint16List _indices = Uint16List.fromList(const [0, 1, 2, 1, 3, 2]);

  void update(
    ProjectedCell cell, {
    required Size size,
    required ui.Image texture,
    required double opacity,
    required bool mirrorX,
    required bool isBack,
  }) {
    for (var index = 0; index < cell.vertices.length; index++) {
      final vertex = cell.vertices[index];
      _positions[index * 2] = vertex.offset.dx;
      _positions[index * 2 + 1] = vertex.offset.dy;
      final horizontalU = vertex.materialX / size.width;
      _textureCoordinates[index * 2] =
          (mirrorX ? 1 - horizontalU : horizontalU) * texture.width;
      _textureCoordinates[index * 2 + 1] =
          vertex.materialY / size.height * texture.height;
      final channel =
          (pageTurnLight(vertex.angle, isBack: isBack) * 255).round();
      _colors[index] =
          Color.fromRGBO(channel, channel, channel, opacity).toARGB32();
    }
  }

  ui.Vertices toVertices() {
    return ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      textureCoordinates: _textureCoordinates,
      colors: _colors,
      indices: _indices,
    );
  }
}

double pageTurnLight(double angle, {required bool isBack}) {
  final edgeOn = math.pow(math.sin(angle).abs(), 1.6).toDouble();
  final flatLight = isBack ? 0.93 : 1.0;
  final foldLight = isBack ? 0.64 : 0.58;
  return ui.lerpDouble(flatLight, foldLight, edgeOn)!.clamp(0.0, 1.0);
}
