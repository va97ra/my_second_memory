import 'dart:ui';

const double windowsTrayWindowWidth = 420;
const double windowsTrayWindowHeight = 900;
const double windowsTrayWindowMargin = 8;

Rect calculateWindowsTrayWindowBounds(Rect workArea) {
  final availableWidth = (workArea.width - windowsTrayWindowMargin * 2)
      .clamp(0.0, double.infinity);
  final availableHeight = (workArea.height - windowsTrayWindowMargin * 2)
      .clamp(0.0, double.infinity);
  final width = windowsTrayWindowWidth.clamp(0.0, availableWidth);
  final height = windowsTrayWindowHeight.clamp(0.0, availableHeight);

  return Rect.fromLTWH(
    workArea.right - width - windowsTrayWindowMargin,
    workArea.bottom - height - windowsTrayWindowMargin,
    width,
    height,
  );
}

Rect nearestWorkArea(Offset point, Iterable<Rect> workAreas) {
  return workAreas.reduce((nearest, candidate) {
    return _distanceSquaredToRect(point, candidate) <
            _distanceSquaredToRect(point, nearest)
        ? candidate
        : nearest;
  });
}

double _distanceSquaredToRect(Offset point, Rect rect) {
  final dx = point.dx < rect.left
      ? rect.left - point.dx
      : point.dx > rect.right
          ? point.dx - rect.right
          : 0.0;
  final dy = point.dy < rect.top
      ? rect.top - point.dy
      : point.dy > rect.bottom
          ? point.dy - rect.bottom
          : 0.0;
  return dx * dx + dy * dy;
}
