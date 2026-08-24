import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'calendar_cell_border_painter.dart';
import 'calendar_day_cell_body.dart';

/// Ячейка дня в сетке месяца: её фон, рамка и содержимое.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.locale,
    required this.isInVisibleMonth,
    required this.isSelected,
    required this.isToday,
    required this.items,
    required this.shiftSchedules,
    required this.holidays,
    required this.hasAlarm,
    required this.onTap,
  });

  final DateTime date;
  final String locale;
  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final List<MemoryItem> items;
  final List<ShiftSchedule> shiftSchedules;
  final List<HolidayOccurrence> holidays;
  final bool hasAlarm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Ячейка — тоже отдельный листок: она держит светлую схему на тёмном
    // блокноте и берёт свои чернила, а не чернила страницы.
    return NotebookPaperIsland(child: Builder(builder: _buildCell));
  }

  Widget _buildCell(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = AppSurfacePalette.of(context);
    final foreground = isInVisibleMonth
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.38);
    // Обычный день соседнего месяца обходится нарисованной рамкой: она дешевле
    // и не спорит с рамками выбранного дня и сегодня.
    final usesGradientBorder =
        isInVisibleMonth && !isSelected && !isToday && items.isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: usesGradientBorder
            ? CalendarCellBorderPainter(
                borderStart: palette.borderStart,
                borderEnd: palette.borderEnd,
              )
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: _decoration(context, colors, palette),
          child: CalendarDayCellBody(
            date: date,
            locale: locale,
            isInVisibleMonth: isInVisibleMonth,
            isSelected: isSelected,
            isToday: isToday,
            items: items,
            shiftSchedules: shiftSchedules,
            holidays: holidays,
            hasAlarm: hasAlarm,
            foreground: foreground,
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(
    BuildContext context,
    ColorScheme colors,
    AppSurfacePalette palette,
  ) {
    final hasShift = shiftSchedules.isNotEmpty && isInVisibleMonth;

    return BoxDecoration(
      gradient: isSelected
          ? palette.accentGradient
          : isInVisibleMonth
              ? palette.surfaceGradient(
                  base: _cellColor(colors, palette, hasShift),
                )
              : null,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isToday
            ? colors.primary
            : isSelected
                ? colors.onSurface
                : items.isNotEmpty && isInVisibleMonth
                    ? colors.outline
                    : Colors.transparent,
        width: isToday
            ? 2.5
            : isSelected
                ? 2
                : 1,
      ),
      boxShadow: _shadow(context, colors),
    );
  }

  List<BoxShadow>? _shadow(BuildContext context, ColorScheme colors) {
    if (isSelected || isToday) {
      return [
        BoxShadow(
          color: (isToday ? colors.primary : colors.onSurface)
              .withValues(alpha: isToday ? 0.34 : 0.16),
          blurRadius: isToday ? 10 : 14,
          spreadRadius: isToday ? 1 : 0,
          offset: Offset(0, isToday ? 2 : 7),
        ),
      ];
    }
    if (NotebookVisuals.maybeOf(context) == null) return null;
    return notebookSurfaceShadow(context, NotebookSurfaceDepth.tile);
  }

  Color _cellColor(
    ColorScheme colors,
    AppSurfacePalette palette,
    bool hasShift,
  ) {
    if (hasShift) return colors.surface;
    if (isToday) {
      return Color.alphaBlend(
        colors.primary.withValues(alpha: 0.16),
        palette.calendarTile,
      );
    }
    // Заливка одна и та же независимо от того, есть ли в дне записи: их
    // наличие показывает рамка, а не фон.
    return isInVisibleMonth ? palette.calendarTile : Colors.transparent;
  }
}
