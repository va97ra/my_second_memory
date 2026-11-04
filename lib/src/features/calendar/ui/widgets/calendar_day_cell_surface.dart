import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'calendar_day_cell.dart';

/// Цвет отметки сегодняшнего дня: рамка ячейки и кружок под числом.
Color calendarTodayColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppPalette.today
        : AppPalette.todayOnLight;

/// Бумага ячейки дня: заливка, рамка и тень.
///
/// Одно место, где решается, чем день отличается от соседей: выбором,
/// записями и тем, что он сегодня. Сама ячейка занята содержимым и нажатием.
@immutable
class CalendarDayCellSurface {
  const CalendarDayCellSurface({
    required this.isInVisibleMonth,
    required this.isToday,
    required this.hasItems,
    required this.todayColor,
    this.dayOff = false,
    this.shortened = false,
  });

  final bool isInVisibleMonth;
  final bool isToday;
  final bool hasItems;

  /// Цвет отметки сегодня. Приходит снаружи: ячейка лежит на листке светлой темы,
  /// и своя тема ей не подскажет, на какой странице она лежит.
  final Color todayColor;
  final bool dayOff;
  final bool shortened;

  bool get _ringsToday => isToday && isInVisibleMonth;

  BoxDecoration decoration(
    BuildContext context,
    ColorScheme colors,
    AppSurfacePalette palette,
  ) {
    return BoxDecoration(
      // Сегодня отмечено рамкой и кружком под числом, бумага у него обычная:
      // подмес цвета давал мутное пятно.
      gradient: isInVisibleMonth
          ? palette.surfaceGradient(base: _paper(colors, palette))
          : null,
      borderRadius: BorderRadius.circular(CalendarDayCell.cornerRadius),
      border: Border.all(
        color: _ringsToday
            ? todayColor
            : hasItems && isInVisibleMonth
                ? colors.outline
                : Colors.transparent,
        width: _ringsToday ? 2.6 : 1,
      ),
      boxShadow: _shadow(context, colors),
    );
  }

  List<BoxShadow>? _shadow(BuildContext context, ColorScheme colors) {
    if (_ringsToday) {
      return [
        BoxShadow(
          color: todayColor.withValues(alpha: 0.6),
          blurRadius: 9,
        ),
      ];
    }
    if (NotebookVisuals.maybeOf(context) == null) return null;
    return notebookSurfaceShadow(context, NotebookSurfaceDepth.tile);
  }

  /// Заливка одна и та же и для дня с записями, и для дня без них, и для
  /// сегодняшнего: записи показывает рамка, смену — полоса сверху, а бумага
  /// говорит только о том, рабочий ли это день.
  Color _paper(ColorScheme colors, AppSurfacePalette palette) {
    if (!isInVisibleMonth) return Colors.transparent;
    return productionDaySurface(palette.calendarTile,
        dayOff: dayOff, shortened: shortened);
  }
}
