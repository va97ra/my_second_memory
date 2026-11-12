import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/calendar_today_provider.dart';
import '../state/calendar_view.dart';
import 'calendar_screen.dart';
import 'widgets/calendar_year_geometry.dart';

/// Переход календаря между месяцем и годом: щипок, нажатие на маленький
/// месяц и кнопка «сегодня» на годовом виде.
///
/// Пока идёт переход, [zoomMonth] — месяц, который сворачивается в свою клетку
/// или вырастает из неё; между переходами он `null`, и на экране одна
/// страница — месяца или года.
mixin CalendarZoomHandling on ConsumerState<CalendarScreen>, TickerProvider {
  static const _duration = Duration(milliseconds: 320);

  late final AnimationController zoom = AnimationController(
    vsync: this,
    duration: _duration,
  );

  DateTime? zoomMonth;

  CalendarView get view;
  set view(CalendarView value);

  /// Идёт листание страницы: переход масштаба его не перебивает.
  bool get isTurningPage;

  /// Идёт переход масштаба.
  bool get isZooming => zoomMonth != null;

  void disposeZoom() => zoom.dispose();

  DateTime get _todayMonth {
    final today = ref.read(calendarTodayProvider);
    return DateTime(today.year, today.month);
  }

  /// Пальцы двигаются: страница следует за ними. На годовом виде из клетки
  /// растёт сегодняшний месяц — даже если показан другой год.
  void pinchUpdate(double scale, CalendarYearGeometry geometry) {
    if (isTurningPage || zoom.isAnimating) return;
    if (zoomMonth == null) {
      setState(() => zoomMonth = view.showsYear ? _todayMonth : view.month);
    }
    zoom.value = geometry.zoomForPinch(scale, view.zoom);
  }

  /// Пальцы подняты: сдвинули на четверть — масштаб меняется, иначе страница
  /// возвращается, как была.
  void pinchEnd(double scale) {
    final month = zoomMonth;
    if (month == null || zoom.isAnimating) return;
    final result = view.pinchResult(scale);
    setState(() {
      view = switch (result) {
        CalendarZoom.year => view.zoomOut(),
        CalendarZoom.month => view.zoomInto(month),
        null => view,
      };
    });
    _settle();
  }

  /// Нажатие на маленький месяц и «сегодня» на годовом виде: месяц вырастает
  /// из своей клетки.
  void openMonth(DateTime month) {
    if (isTurningPage || isZooming) return;
    setState(() {
      zoomMonth = DateTime(month.year, month.month);
      view = view.zoomInto(month);
    });
    zoom.value = 1;
    _settle();
  }

  void openTodayMonth() => openMonth(_todayMonth);

  void _settle() {
    zoom
        .animateTo(
      view.showsYear ? 1 : 0,
      duration: _duration,
      curve: Curves.easeOutCubic,
    )
        .whenCompleteOrCancel(() {
      if (mounted) setState(() => zoomMonth = null);
    });
  }
}
