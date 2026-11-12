import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../state/calendar_view.dart';

/// Где на странице года лежит каждый месяц.
///
/// Одна раскладка на сетку года и на переход масштаба: месяц сворачивается
/// ровно в ту клетку, в которой его потом видно, и вырастает из неё же.
@immutable
class CalendarYearGeometry {
  const CalendarYearGeometry(this.size);

  /// Страница календаря целиком — та же, что занимает месяц.
  final Size size;

  /// Поля страницы — те же, что у страницы месяца.
  static const padding = EdgeInsets.fromLTRB(10, 0, 10, 10);
  static const spacing = 10.0;

  /// В ландшафте четыре месяца в ряд, в портрете три.
  int get columns => size.width > size.height ? 4 : 3;
  int get rows => 12 ~/ columns;

  Rect get page => Offset.zero & size;

  /// Клетка месяца с номером [month] от 1 до 12.
  Rect monthRect(int month) {
    final area = padding.deflateRect(page);
    final width = (area.width - spacing * (columns - 1)) / columns;
    final height = (area.height - spacing * (rows - 1)) / rows;
    final index = month - 1;
    return Rect.fromLTWH(
      area.left + (index % columns) * (width + spacing),
      area.top + (index ~/ columns) * (height + spacing),
      math.max(0, width),
      math.max(0, height),
    );
  }

  /// Во сколько раз клетка месяца меньше страницы. Клетка и страница разной
  /// формы, поэтому берётся среднее по ширине и высоте.
  double get _monthShare {
    final cell = monthRect(1);
    if (size.isEmpty) return 1;
    return math.sqrt(cell.width / size.width * (cell.height / size.height));
  }

  /// Насколько календарь ушёл к году, от 0 (месяц) до 1 (год), когда пальцы
  /// развели в [scale] раз, начав в масштабе [from]. Страница меняется ровно
  /// во столько раз, во сколько изменилось расстояние между пальцами.
  double zoomForPinch(double scale, CalendarZoom from) {
    final share = _monthShare;
    if (share >= 1) return from == CalendarZoom.year ? 1 : 0;
    final zoom = switch (from) {
      CalendarZoom.month => (1 - scale) / (1 - share),
      CalendarZoom.year => (1 / share - scale) / (1 / share - 1),
    };
    return zoom.clamp(0.0, 1.0);
  }

  /// Преобразование, кладущее прямоугольник [from] на [to].
  static Matrix4 fit(Rect from, Rect to) {
    if (from.isEmpty) return Matrix4.identity();
    return Matrix4.identity()
      ..translateByDouble(to.left, to.top, 0, 1)
      ..scaleByDouble(to.width / from.width, to.height / from.height, 1, 1)
      ..translateByDouble(-from.left, -from.top, 0, 1);
  }
}
