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
  });

  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasItems;

  /// Насколько сегодняшний день темнее соседних. Столько, чтобы его было
  /// видно боковым зрением, и не столько, чтобы записи в нём читались хуже.
  static const todayShadeOpacity = 0.14;

  BoxDecoration decoration(
    BuildContext context,
    ColorScheme colors,
    AppSurfacePalette palette,
  ) {
    return BoxDecoration(
      // Сегодня отмечено серой тенью на бумаге: чёрная обводка спорила с
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
            : hasItems && isInVisibleMonth
                ? colors.outline
                : Colors.transparent,
        width: isSelected ? 2 : 1,
      ),
      boxShadow: _shadow(context, colors),
    );
  }

  List<BoxShadow>? _shadow(BuildContext context, ColorScheme colors) {
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
  /// Сегодняшний день — та же бумага, притенённая серым.
  Color _paper(ColorScheme colors, AppSurfacePalette palette) {
    if (!isInVisibleMonth) return Colors.transparent;
    if (!isToday) return palette.calendarTile;
    return Color.alphaBlend(
      colors.onSurface.withValues(alpha: todayShadeOpacity),
      palette.calendarTile,
    );
  }
}
