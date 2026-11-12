import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/production_calendar_provider.dart';
import '../../state/production_preferences.dart';

import 'calendar_cell_border_painter.dart';
import 'calendar_day_cell_body.dart';
import 'calendar_day_cell_surface.dart';
import 'calendar_day_press_effect.dart';

/// Ячейка дня в сетке месяца: её фон, рамка и содержимое.
class CalendarDayCell extends ConsumerWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.locale,
    required this.isInVisibleMonth,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final day =
        ref.watch(productionCalendarProvider(date.year)).calendar.day(date);
    final highlight =
        ref.watch(productionPreferencesProvider.select((s) => s.highlight));
    final todayColor = calendarTodayColor(context);
    return NotebookPaperIsland(
      child: Builder(
        builder: (context) => _buildCell(context, day, highlight, todayColor),
      ),
    );
  }

  /// Выходной и сокращённый день залиты чистым цветом: чернила выбираются по нему.
  Color _inkOnPaper(
    ColorScheme colors,
    ProductionDay? productionDay,
    bool highlight,
  ) {
    if (!highlight) return colors.onSurface;
    if (productionDay == ProductionDay.shortened) {
      return readableInkOn(AppPalette.shortenedDay);
    }
    return productionDay?.isDayOff ?? false
        ? readableInkOn(AppPalette.weekend)
        : colors.onSurface;
  }

  Widget _buildCell(
    BuildContext context,
    ProductionDay? productionDay,
    bool highlight,
    Color todayColor,
  ) {
    final colors = Theme.of(context).colorScheme;
    final palette = AppSurfacePalette.of(context);
    // Число, будильник и отметка архива стоят на шапке графика, а цвет ей
    // задаёт человек: чернила выбираются по её светлоте, иначе на светлом
    // графике белое число пропадает.
    final foreground = !isInVisibleMonth
        ? colors.onSurface.withValues(alpha: 0.38)
        : shiftSchedules.isEmpty
            ? _inkOnPaper(colors, productionDay, highlight)
            : readableInkOn(Color(shiftSchedules.first.colorValue));
    // Рамка нужна только пустым плиткам видимого месяца: у остальных край
    // задаёт заливка.
    final usesGradientBorder = isInVisibleMonth && items.isEmpty && !isToday;

    // Нажатие рисуется поверх плитки, а не под ней: `InkWell` снаружи
    // заливки отдаёт свою волну ближайшему материалу выше — материалу
    // `Scaffold`, — и проступает поверх страницы.
    final pressable = NotebookPressable(
      onTap: onTap,
      playClick: false,
      pulse: false,
      borderRadius: BorderRadius.circular(cornerRadius),
      child: CalendarDayCellBody(
        productionDay: productionDay,
        date: date,
        locale: locale,
        isInVisibleMonth: isInVisibleMonth,
        isToday: isToday,
        items: items,
        shiftSchedules: shiftSchedules,
        holidays: holidays,
        hasAlarm: hasAlarm,
        foreground: foreground,
        todayColor: todayColor,
        stamp: highlight && isInVisibleMonth && productionDay != null
            ? AppStrings.of(context).productionDayStamp(productionDay.name)
            : null,
      ),
    );
    return CalendarDayPressEffect(
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
            dayOff: highlight && (productionDay?.isDayOff ?? false),
            shortened: highlight && productionDay == ProductionDay.shortened,
            isInVisibleMonth: isInVisibleMonth,
            isToday: isToday,
            hasItems: items.isNotEmpty,
            todayColor: todayColor,
          ).decoration(context, colors, palette),
          child: pressable,
        ),
      ),
    );
  }
}
