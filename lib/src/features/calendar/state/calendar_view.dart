import 'package:flutter/foundation.dart';

/// Что показывает календарь: страницу месяца или весь год.
enum CalendarZoom { month, year }

/// Видимый месяц и масштаб календаря.
///
/// В годовом виде [month] остаётся месяцем, из которого год открыли: его
/// клетка — то место, куда сворачивается страница и откуда она вырастает.
@immutable
class CalendarView {
  CalendarView({required DateTime month, this.zoom = CalendarZoom.month})
      : month = DateTime(month.year, month.month);

  /// Насколько должно измениться расстояние между пальцами, чтобы щипок
  /// сменил масштаб: на четверть. Меньшее движение возвращает всё как было.
  static const pinchThreshold = 0.25;

  final DateTime month;
  final CalendarZoom zoom;

  int get year => month.year;
  bool get showsYear => zoom == CalendarZoom.year;

  /// Шаг стрелкой или смахиванием вбок: месяц на странице месяца, год — на
  /// годовом виде.
  CalendarView step(int offset) => showsYear
      ? stepYear(offset)
      : CalendarView(month: DateTime(year, month.month + offset), zoom: zoom);

  /// Шаг смахиванием вверх или вниз: год в любом масштабе.
  CalendarView stepYear(int offset) =>
      CalendarView(month: DateTime(year + offset, month.month), zoom: zoom);

  CalendarView zoomOut() => CalendarView(month: month, zoom: CalendarZoom.year);

  CalendarView zoomInto(DateTime month) => CalendarView(month: month);

  /// Чем кончится щипок с таким отношением расстояний между пальцами, или
  /// `null`, если масштаб остаётся прежним.
  CalendarZoom? pinchResult(double scale) {
    if (!showsYear && scale <= 1 - pinchThreshold) return CalendarZoom.year;
    if (showsYear && scale >= 1 / (1 - pinchThreshold)) {
      return CalendarZoom.month;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarView && other.month == month && other.zoom == zoom;

  @override
  int get hashCode => Object.hash(month, zoom);
}
