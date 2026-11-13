import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/shift_schedule_color.dart';
import 'calendar_day_cell.dart';

/// Цвет отметки сегодняшнего дня: рамка ячейки и кружок под числом.
Color calendarTodayColor(BuildContext context) =>
    AppThemeColors.of(context)[AppColorRole.today];

/// Чернила числа и значков дня — одни для большой ячейки и для миниатюры года.
///
/// Число стоит на шапке графика, а её цвет задаёт человек: чернила выбираются
/// по её светлоте, иначе на светлом графике белое число пропадает. Без смены
/// число стоит на бумаге дня, а выходной и сокращённый залиты чистым цветом.
Color calendarDayInk(
  ColorScheme colors,
  AppThemeColors themeColors, {
  required bool isInVisibleMonth,
  required List<ShiftSchedule> shifts,
  required ProductionDay? productionDay,
  required bool highlight,
}) {
  if (!isInVisibleMonth) return colors.onSurface.withValues(alpha: 0.38);
  if (shifts.isNotEmpty) {
    return readableInkOn(shiftScheduleColor(themeColors, shifts.first));
  }
  if (!highlight) return colors.onSurface;
  if (productionDay == ProductionDay.shortened) {
    return readableInkOn(themeColors[AppColorRole.shortenedDay]);
  }
  return productionDay?.isDayOff ?? false
      ? readableInkOn(themeColors[AppColorRole.weekend])
      : colors.onSurface;
}

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
    required this.themeColors,
    this.dayOff = false,
    this.shortened = false,
  });

  final bool isInVisibleMonth;
  final bool isToday;
  final bool hasItems;

  /// Цвета темы страницы: ими отмечены сегодня, выходной и сокращённый день.
  final AppThemeColors themeColors;
  final bool dayOff;
  final bool shortened;

  bool get _ringsToday => isToday && isInVisibleMonth;

  Color get todayColor => themeColors[AppColorRole.today];

  BoxDecoration decoration(
    BuildContext context,
    ColorScheme colors,
    AppSurfacePalette palette,
  ) {
    return BoxDecoration(
      // Сегодня отмечено рамкой и кружком под числом, бумага у него обычная:
      // подмес цвета давал мутное пятно.
      gradient: isInVisibleMonth
          ? palette.surfaceGradient(base: paper(palette))
          : null,
      borderRadius: BorderRadius.circular(CalendarDayCell.cornerRadius),
      border: Border.all(
        color: borderColor(colors),
        width: _ringsToday ? 2.6 : 1,
      ),
      boxShadow: _shadow(context, colors),
    );
  }

  /// Рамка: сегодняшний день обведён своим цветом, день с записями — тонкой
  /// линией, остальные без рамки.
  Color borderColor(ColorScheme colors) => _ringsToday
      ? todayColor
      : hasItems && isInVisibleMonth
          ? colors.outline
          : Colors.transparent;

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
  Color paper(AppSurfacePalette palette) {
    if (!isInVisibleMonth) return Colors.transparent;
    return productionDaySurface(palette.calendarTile, themeColors,
        dayOff: dayOff, shortened: shortened);
  }
}
