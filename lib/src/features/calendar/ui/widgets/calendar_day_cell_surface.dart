import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'calendar_day_cell.dart';

/// Цвет отметки сегодняшнего дня: рамка ячейки и кружок под числом.
///
/// Зелёный нарочно: красный в сетке заняли выходные, синий — шапки графиков
/// и записи, и отметка этих цветов с ними сливалась.
const calendarTodayGreen = Color(0xFF00A152);

Color calendarTodayColor(BuildContext context) =>
    ScreenVisuals.maybeOf(context)?.colors.today ?? calendarTodayGreen;

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
    this.screen,
    this.dayOff = false,
    this.shortened = false,
  });

  final bool isInVisibleMonth;
  final bool isToday;
  final bool hasItems;
  final bool dayOff;
  final bool shortened;

  /// Значения экранной темы или null в блокноте.
  final ScreenThemeColors? screen;

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
          ? screen == null
              ? palette.surfaceGradient(base: _paper(colors, palette))
              : _glass(_paper(colors, palette))
          : null,
      borderRadius: BorderRadius.circular(CalendarDayCell.cornerRadius),
      border: Border.all(
        color: _ringsToday
            ? calendarTodayColor(context)
            : hasItems && isInVisibleMonth
                ? colors.outline
                : Colors.transparent,
        width: _ringsToday ? 2.6 : 1,
      ),
      boxShadow: _shadow(context, colors),
    );
  }

  /// Плитка дня — та же пластина стекла, что и панели: одно стекло на всё
  /// приложение, чтобы сетка и панели не расходились между собой.
  LinearGradient _glass(Color tile) =>
      GlassSurface.gradient(screen!, tile, clearPlate: true);

  List<BoxShadow>? _shadow(BuildContext context, ColorScheme colors) {
    final screen = this.screen;
    if (_ringsToday) {
      return [
        BoxShadow(
          color: calendarTodayColor(context).withValues(alpha: 0.6),
          blurRadius: 9,
        ),
      ];
    }
    if (screen != null && isInVisibleMonth) {
      // Пластина лежит на заднике, а не врезана в него: под ней тень в свою
      // же толщину.
      return [
        ...GlassSurface.shadow(screen),
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
