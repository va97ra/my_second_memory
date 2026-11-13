import 'dart:ui';

/// Окно на Windows — телефон: экран приложения в корпусе. Экран того же
/// размера, что был у окна без корпуса, корпус добавляется вокруг.
const double windowsPhoneScreenWidth = 420;
const double windowsPhoneScreenHeight = 868;

/// Рамка корпуса вокруг экрана: по бокам, сверху (там камера и кнопки
/// окна) и снизу.
const double windowsPhoneBezelSide = 11;
const double windowsPhoneBezelTop = 26;
const double windowsPhoneBezelBottom = 14;

/// Кнопки питания и громкости выступают за корпус справа.
const double windowsPhoneSideButtonsOutset = 3;

const double windowsTrayWindowWidth = windowsPhoneScreenWidth +
    windowsPhoneBezelSide * 2 +
    windowsPhoneSideButtonsOutset;
const double windowsTrayWindowHeight =
    windowsPhoneScreenHeight + windowsPhoneBezelTop + windowsPhoneBezelBottom;
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
