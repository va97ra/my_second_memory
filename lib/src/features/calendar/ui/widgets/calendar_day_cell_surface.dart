import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'calendar_day_cell.dart';

/// Бумага ячейки дня: заливка, рамка и тень.
///
/// Одно место, где решается, чем день отличается от соседей: выбором,
/// записями и тем, что он сегодня. Сама ячейка занята содержимым и нажатием.
@immutable
class CalendarDayCellSurface {
  const CalendarDayCellSurface({
    required this.isInVisibleMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasItems,
    this.screen,
  });

  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasItems;

  /// Значения экранной темы или null в блокноте.
  ///
  /// Заливка сегодняшнего дня рассчитана на светлую плитку: подмешанная к ней
  /// отметка светлеет, и день выступает вперёд. На тёмной плитке та же
  /// примесь темнеет и даёт грязное пятно — день выглядит не отмеченным, а
  /// испачканным. Поэтому на тёмной теме сегодня получает цветную шапку и
  /// свечение, а плитка остаётся обычной; на светлой — подложку, как и на
  /// бумаге. Обводка отметкой есть в обеих.
  final ScreenThemeColors? screen;

  bool get _ringsToday => isToday && isInVisibleMonth && screen != null;

  /// Насколько сегодняшний день отделён от соседних.
  ///
  /// Подмешивается акцентный цвет приложения: притенение цветом текста давало
  /// серую плитку, и сегодня выглядел не отмеченным, а выцветшим.
  ///
  /// Больше трёх десятых брать нельзя: заливка становится плотной, и тексту
  /// записей поверх неё перестаёт хватать запаса контраста.
  static const todayTintOpacity = 0.28;

  BoxDecoration decoration(
    BuildContext context,
    ColorScheme colors,
    AppSurfacePalette palette,
  ) {
    return BoxDecoration(
      // Сегодня отмечено подкрашенной бумагой: чёрная обводка спорила с
      // рамками соседей и терялась среди них. В день открытия сегодня — ещё
      // и выбранный день, и акцентная заливка его примету не съедает: их
      // теперь двое, заливка и рамка выбора.
      gradient: isSelected && !isToday
          ? palette.accentGradient
          : isInVisibleMonth
              ? palette.surfaceGradient(base: _paper(colors, palette))
              : null,
      borderRadius: BorderRadius.circular(CalendarDayCell.cornerRadius),
      border: Border.all(
        color: isSelected
            ? colors.onSurface
            : _ringsToday
                ? screen!.today
                : hasItems && isInVisibleMonth
                    ? colors.outline
                    : Colors.transparent,
        width: isSelected ? 2 : (_ringsToday ? 1.4 : 1),
      ),
      boxShadow: _shadow(context, colors),
    );
  }

  List<BoxShadow>? _shadow(BuildContext context, ColorScheme colors) {
    if (_ringsToday && !isSelected) {
      return [
        BoxShadow(
          color: screen!.glow.withValues(alpha: screen!.isDark ? 0.45 : 0.3),
          blurRadius: 10,
        ),
      ];
    }
    if (isSelected) {
      return [
        BoxShadow(
          color: colors.onSurface.withValues(alpha: 0.16),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ];
    }
    if (NotebookVisuals.maybeOf(context) == null) return null;
    return notebookSurfaceShadow(context, NotebookSurfaceDepth.tile);
  }

  /// Заливка одна и та же и для дня с записями, и для дня со сменой: записи
  /// показывает рамка, смену — полоса сверху, а бумага под ними одна.
  /// Сегодняшний день — та же бумага, подкрашенная акцентом.
  Color _paper(ColorScheme colors, AppSurfacePalette palette) {
    if (!isInVisibleMonth) return Colors.transparent;
    if (!isToday) return palette.calendarTile;
    final screen = this.screen;
    if (screen == null) {
      return Color.alphaBlend(
        colors.primary.withValues(alpha: todayTintOpacity),
        palette.calendarTile,
      );
    }
    if (screen.isDark) return palette.calendarTile;
    return Color.alphaBlend(
      screen.today.withValues(alpha: 0.12),
      palette.calendarTile,
    );
  }
}
