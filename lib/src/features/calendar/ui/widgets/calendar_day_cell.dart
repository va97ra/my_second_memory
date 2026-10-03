import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/production_calendar_provider.dart';
import '../../state/production_preferences.dart';

import 'calendar_cell_border_painter.dart';
import 'calendar_day_cell_body.dart';
import 'calendar_day_cell_surface.dart';

/// Ячейка дня в сетке месяца: её фон, рамка и содержимое.
class CalendarDayCell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final day =
        ref.watch(productionCalendarProvider(date.year)).calendar.day(date);
    final highlight =
        ref.watch(productionPreferencesProvider.select((s) => s.highlight));
    return NotebookPaperIsland(
        child:
            Builder(builder: (context) => _buildCell(context, day, highlight)));
  }

  Widget _buildCell(
      BuildContext context, ProductionDay? productionDay, bool highlight) {
    final colors = Theme.of(context).colorScheme;
    final palette = AppSurfacePalette.of(context);
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    // На тёмной теме сегодня получает шапку, только если её не заняла смена.
    final todayCap = isToday &&
            isInVisibleMonth &&
            shiftSchedules.isEmpty &&
            (screen?.isDark ?? false)
        ? screen!.today
        : null;
    // Число, будильник и отметка архива стоят на шапке графика, а цвет ей
    // задаёт человек: чернила выбираются по её светлоте, иначе на светлом
    // графике белое число пропадает.
    final foreground = !isInVisibleMonth
        ? colors.onSurface.withValues(alpha: 0.38)
        : todayCap != null
            ? readableInkOn(todayCap)
            : shiftSchedules.isEmpty
                ? colors.onSurface
                : readableInkOn(Color(shiftSchedules.first.colorValue));
    // У экранного стекла своя тонкая кромка. Дополнительная рамка нужна
    // только бумажным плиткам блокнота.
    final usesGradientBorder = screen == null &&
        isInVisibleMonth &&
        !isSelected &&
        items.isEmpty &&
        !(isToday && screen != null);

    // Нажатие рисуется поверх плитки, а не под ней: `InkWell` снаружи
    // заливки отдаёт свою волну ближайшему материалу выше — материалу
    // `Scaffold`, — и сквозь стеклянную плитку она проступает белым.
    final pressable = NotebookPressable(
      onTap: onTap,
      playClick: false,
      pressedOffset: 0,
      borderRadius: BorderRadius.circular(cornerRadius),
      child: CalendarDayCellBody(
        productionDay: productionDay,
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
        todayCap: todayCap,
        outlinedNumber: screen == null,
      ),
    );
    // Цветные отражения не обязательны для преломления: у «Космоса» стекло
    // нейтральное, но освещённые кромки прямой пластины тоже видны.
    final contents = screen == null
        ? pressable
        : ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius),
            child: CustomPaint(
              key: const ValueKey('calendar_day_glass_lens'),
              foregroundPainter: ScreenGlassSurfacePainter(
                colors: screen,
                pressed: false,
                profile: ScreenGlassProfile.plate,
                radius: cornerRadius,
              ),
              child: pressable,
            ),
          );
    return CustomPaint(
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
          isSelected: isSelected,
          isToday: isToday,
          hasItems: items.isNotEmpty,
          screen: screen,
        ).decoration(context, colors, palette),
        child: contents,
      ),
    );
  }
}
