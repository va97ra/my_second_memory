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
              ? screen == null
                  ? palette.surfaceGradient(base: _paper(colors, palette))
                  : _glass(_paper(colors, palette))
              : null,
      borderRadius: BorderRadius.circular(CalendarDayCell.cornerRadius),
      // Отметка сегодня сильнее рамки выбора: в день открытия сегодня и есть
      // выбранный день, и тёмная рамка выбора стирала его примету — день
      // выглядел как любой другой, по которому нажали.
      border: Border.all(
        color: _ringsToday
            ? screen!.today
            : isSelected
                ? colors.onSurface
                : hasItems && isInVisibleMonth
                    ? colors.outline
                    : screen != null && isInVisibleMonth
                        ? screen!.glint.withValues(
                            alpha: screen!.isDark ? 0.2 : 0.55,
                          )
                        : Colors.transparent,
        width: _ringsToday ? 1.8 : (isSelected ? 2 : 1),
      ),
      boxShadow: _shadow(context, colors),
    );
  }

  /// Плитка дня как пластина стекла.
  ///
  /// Стекло толщиной три миллиметра при ширине плитки в двадцать пять — так
  /// её мерил владелец, — то есть ребро занимает двенадцать сотых ширины.
  /// Свет падает сверху слева: там ребро светится, на противоположном оно
  /// притенено, а между ними ровное матовое поле. Отсюда и стопы: 0.12 и 0.88.
  ///
  /// Светится ребро не белым, а светом задника: тёплым от планет, холодным от
  /// неона. Белое ребро выдаёт накладку — так стекло не ведёт себя ни на одном
  /// фоне.
  LinearGradient _glass(Color tile) {
    final c = screen!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(c.glint.withValues(alpha: 0.62), tile),
        tile,
        tile,
        Color.alphaBlend(
          Colors.black.withValues(alpha: c.isDark ? 0.3 : 0.11),
          tile,
        ),
      ],
      stops: const [0, 0.12, 0.88, 1],
    );
  }

  List<BoxShadow>? _shadow(BuildContext context, ColorScheme colors) {
    final screen = this.screen;
    if (_ringsToday) {
      return [
        BoxShadow(
          color: screen!.glow.withValues(alpha: screen.isDark ? 0.45 : 0.3),
          blurRadius: 10,
        ),
      ];
    }
    if (screen != null && isInVisibleMonth && !isSelected) {
      // Пластина лежит на заднике, а не врезана в него: под ней тень в свою
      // же толщину.
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: screen.isDark ? 0.45 : 0.12),
          blurRadius: 6,
          offset: const Offset(0, 2),
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
