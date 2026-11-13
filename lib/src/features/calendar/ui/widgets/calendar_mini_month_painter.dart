import 'dart:math' as math;

import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import '../../../../shared/ui/shift_schedule_color.dart';
import '../../state/calendar_month_data.dart';
import 'calendar_day_cell_layout.dart';
import 'calendar_day_cell_surface.dart';

/// Маленький месяц годового вида — миниатюра большой страницы.
///
/// В каждом дне то же, что в ячейке месяца: бумага выходного и сокращённого
/// дня, шапка смены и лента отпуска, полоски записей, праздничная лента,
/// будильник, рамка сегодняшнего дня и число. Слова — названия записей и
/// праздника — в таком размере не читаются и опущены. Цвета и решения берутся
/// из тех же мест, что у большой ячейки, а не повторяются здесь.
///
/// Все дни рисуются одним объектом: на экране двенадцать месяцев, и
/// отдельный виджет на каждый из пятисот дней стоил бы дороже, чем они сами.
class CalendarMiniMonthPainter extends CustomPainter {
  CalendarMiniMonthPainter({
    required this.month,
    required this.data,
    required this.productionDays,
    required this.highlight,
    required this.today,
    required this.colors,
    required this.palette,
    required this.themeColors,
    required this.numberStyle,
  });

  final DateTime month;
  final CalendarMonthData data;
  final ProductionCalendar productionDays;
  final bool highlight;
  final DateTime today;
  final ColorScheme colors;
  final AppSurfacePalette palette;

  /// Цвета темы страницы: сегодня, выходные, графики и виды записей.
  final AppThemeColors themeColors;
  final TextStyle numberStyle;

  static const _gap = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = data.days.length ~/ 7;
    final width = (size.width - _gap * 6) / 7;
    final height = (size.height - _gap * (rows - 1)) / rows;
    if (width <= 0 || height <= 0) return;

    for (var index = 0; index < data.days.length; index++) {
      final day = data.days[index];
      // Дни соседних месяцев пусты, как и на большой странице.
      if (day.month != month.month) continue;
      final cell = Rect.fromLTWH(
        (index % 7) * (width + _gap),
        (index ~/ 7) * (height + _gap),
        width,
        height,
      );
      _paintDay(canvas, cell, day);
    }
  }

  void _paintDay(Canvas canvas, Rect cell, DateTime day) {
    final dayData = data.cellFor(day);
    final productionDay = productionDays.day(day);
    final isToday = isSameDay(day, today);
    final surface = CalendarDayCellSurface(
      isInVisibleMonth: true,
      isToday: isToday,
      hasItems: dayData.items.isNotEmpty,
      themeColors: themeColors,
      dayOff: highlight && (productionDay?.isDayOff ?? false),
      shortened: highlight && productionDay == ProductionDay.shortened,
    );
    final radius = math.min(cell.width, cell.height) * 0.14;
    final shape = RRect.fromRectAndRadius(cell, Radius.circular(radius));

    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(cell, Paint()..color = surface.paper(palette));
    final header = cell.height * 0.24;
    _paintShifts(canvas, cell, day, dayData.shifts, header);
    final holiday = dayData.holidays.isEmpty ? 0.0 : cell.height * 0.2;
    if (holiday > 0) _paintHoliday(canvas, cell, holiday);
    _paintItems(canvas, cell, dayData.items, top: header, bottom: holiday);
    canvas.restore();

    final ink = calendarDayInk(
      colors,
      themeColors,
      isInVisibleMonth: true,
      shifts: dayData.shifts,
      productionDay: productionDay,
      highlight: highlight,
    );
    if (dayData.hasAlarm) {
      canvas.drawCircle(
        Offset(cell.right - cell.width * 0.16, cell.top + header / 2),
        math.max(0.8, cell.width * 0.08),
        Paint()..color = ink,
      );
    }
    _paintNumber(canvas, cell, day.day, ink);

    final border = surface.borderColor(colors);
    if (border.a > 0) {
      canvas.drawRRect(
        shape.deflate(isToday ? 0.7 : 0.3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isToday ? 1.4 : 0.6
          ..color = border,
      );
    }
  }

  /// Каждый график — в своей доле дня: снизу лента отпуска наискосок,
  /// поверх неё цветная шапка, как в [ShiftMarks].
  void _paintShifts(
    Canvas canvas,
    Rect cell,
    DateTime day,
    List<ShiftSchedule> shifts,
    double header,
  ) {
    if (shifts.isEmpty) return;
    final share = cell.width / shifts.length;
    for (var index = 0; index < shifts.length; index++) {
      final schedule = shifts[index];
      final part = Rect.fromLTWH(
        cell.left + share * index,
        cell.top,
        share,
        cell.height,
      );
      if (schedule.isVacationWorkday(day)) {
        canvas
          ..save()
          ..clipRect(part)
          ..drawLine(
            part.bottomLeft,
            part.topRight,
            Paint()
              ..color = AppPalette.vacationCloth
              ..strokeWidth = math.max(1.5, cell.height * 0.2),
          )
          ..restore();
      }
      canvas.drawRect(
        Rect.fromLTWH(part.left, part.top, part.width, header),
        Paint()..color = shiftScheduleColor(themeColors, schedule),
      );
    }
  }

  void _paintHoliday(Canvas canvas, Rect cell, double extent) {
    final band = Rect.fromLTRB(
      cell.left,
      cell.bottom - extent,
      cell.right,
      cell.bottom,
    );
    canvas
      ..drawRect(band, Paint()..color = AppPalette.violet)
      ..drawLine(
        band.topLeft,
        band.topRight,
        Paint()
          ..color = AppPalette.holidayThread
          ..strokeWidth = 0.6,
      );
  }

  /// Полоски записей под шапкой — в том же порядке, что в большой ячейке,
  /// и столько, сколько уместится.
  void _paintItems(
    Canvas canvas,
    Rect cell,
    List<MemoryItem> items, {
    required double top,
    required double bottom,
  }) {
    if (items.isEmpty) return;
    final stripe = math.max(1.0, cell.height * 0.09);
    final inset = cell.width * 0.12;
    var y = cell.top + top + cell.height * 0.32;
    final limit = cell.bottom - bottom - stripe;
    for (final item in sortedDayItems(items)) {
      if (y > limit) break;
      canvas.drawRect(
        Rect.fromLTWH(cell.left + inset, y, cell.width - inset * 2, stripe),
        Paint()..color = memoryAccentColor(themeColors, item),
      );
      y += stripe + math.max(0.6, stripe * 0.5);
    }
  }

  void _paintNumber(Canvas canvas, Rect cell, int number, Color ink) {
    final fontSize = math.min(cell.height * 0.42, cell.width * 0.5);
    if (fontSize < 4) return;
    final text = TextPainter(
      text: TextSpan(
        text: '$number',
        style: numberStyle.copyWith(color: ink, fontSize: fontSize, height: 1),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    text.paint(
      canvas,
      Offset(cell.left + (cell.width - text.width) / 2, cell.top + 0.5),
    );
    text.dispose();
  }

  @override
  bool shouldRepaint(CalendarMiniMonthPainter old) =>
      old.data != data ||
      old.productionDays != productionDays ||
      old.highlight != highlight ||
      old.today != today ||
      old.colors != colors ||
      old.palette != palette ||
      old.themeColors != themeColors ||
      old.numberStyle != numberStyle;
}
