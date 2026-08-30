import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'calendar_cell_border_painter.dart';
import 'calendar_day_cell_body.dart';
import 'calendar_day_cell_surface.dart';

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

  /// Скругление ячейки. Одно на все три места, где оно нужно: нажатие,
  /// заливка и рисованная рамка соседнего месяца.
  static const cornerRadius = 4.0;

  @override
  Widget build(BuildContext context) {
    // Ячейка — тоже отдельный листок: она держит светлую схему на тёмном
    // блокноте и берёт свои чернила, а не чернила страницы.
    return NotebookPaperIsland(child: Builder(builder: _buildCell));
  }

  Widget _buildCell(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = AppSurfacePalette.of(context);
    // Число, будильник и отметка архива стоят на шапке графика, а цвет ей
    // задаёт человек: чернила выбираются по её светлоте, иначе на светлом
    // графике белое число пропадает.
    final foreground = !isInVisibleMonth
        ? colors.onSurface.withValues(alpha: 0.38)
        : shiftSchedules.isEmpty
            ? colors.onSurface
            : readableInkOn(Color(shiftSchedules.first.colorValue));
    // Обычный день обходится нарисованной рамкой: она дешевле и не спорит с
    // рамкой выбранного дня. Сегодня — такой же обычный день: его примета
    // теперь заливка, а не собственная обводка.
    final usesGradientBorder = isInVisibleMonth && !isSelected && items.isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(cornerRadius),
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: usesGradientBorder
            ? CalendarCellBorderPainter(
                borderStart: palette.borderStart,
                borderEnd: palette.borderEnd,
                cornerRadius: cornerRadius,
              )
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          // Обрезает праздничную ленту по скруглению ячейки: она лежит
          // вплотную к нижнему краю и без этого вылезла бы за углы.
          clipBehavior: Clip.antiAlias,
          decoration: CalendarDayCellSurface(
            isInVisibleMonth: isInVisibleMonth,
            isSelected: isSelected,
            isToday: isToday,
            hasItems: items.isNotEmpty,
          ).decoration(context, colors, palette),
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
}
