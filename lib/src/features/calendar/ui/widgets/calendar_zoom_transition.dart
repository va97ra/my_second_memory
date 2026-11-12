import 'package:flutter/material.dart';

import 'calendar_year_geometry.dart';

/// Переход между месяцем и годом: страница месяца сворачивается в свою клетку
/// годовой сетки, а сетка подъезжает к ней из-за краёв, — и обратно.
///
/// [zoom] — от 0 (месяц на всю страницу) до 1 (год). Обе страницы движутся
/// одним движением камеры: клетка [month] всё время лежит там, где сейчас
/// страница месяца, поэтому одна переходит в другую без скачка.
class CalendarZoomTransition extends StatelessWidget {
  const CalendarZoomTransition({
    super.key,
    required this.zoom,
    required this.month,
    required this.monthPage,
    required this.yearPage,
  });

  final Animation<double> zoom;

  /// Номер месяца от 1 до 12 — клетка, в которую сворачивается страница.
  final int month;
  final Widget monthPage;
  final Widget yearPage;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final geometry = CalendarYearGeometry(constraints.biggest);
          final page = geometry.page;
          final cell = geometry.monthRect(month);

          return AnimatedBuilder(
            animation: zoom,
            builder: (context, _) {
              final value = zoom.value.clamp(0.0, 1.0);
              final frame = Rect.lerp(page, cell, value)!;
              return IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      key: const ValueKey('calendar_zoom_year'),
                      opacity: value,
                      child: Transform(
                        transform: CalendarYearGeometry.fit(cell, frame),
                        child: yearPage,
                      ),
                    ),
                    Opacity(
                      key: const ValueKey('calendar_zoom_month'),
                      opacity: 1 - value,
                      child: Transform(
                        transform: CalendarYearGeometry.fit(page, frame),
                        child: monthPage,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
