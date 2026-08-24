import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';

/// Что помещается в ячейку дня при её нынешней высоте.
///
/// Арифметика вынесена из виджета, потому что от неё зависит, увидит ли
/// человек свои записи: ошибка здесь молча прячет их за «+ ещё N», и заметить
/// это можно только глазами на конкретной высоте экрана.
@immutable
class CalendarDayCellLayout {
  const CalendarDayCellLayout({
    required this.visibleItems,
    required this.overflowCount,
    required this.showsHoliday,
    required this.showsEvents,
  });

  factory CalendarDayCellLayout.forCell({
    required double height,
    required List<MemoryItem> items,
    required bool hasHoliday,
  }) {
    final slots = ((height - _headerExtent) / _eventSlotExtent).floor();
    final maxEvents = slots.clamp(0, _maxEventRows);
    // Праздник забирает одну строку: он относится ко всему дню и важнее
    // очередной записи в списке.
    final holidaySlots = hasHoliday && maxEvents > 0 ? 1 : 0;
    final itemSlots = maxEvents - holidaySlots;

    // Если записи не влезают, последняя строка уходит под счётчик остатка —
    // иначе человек не узнает, что за краем ячейки что-то есть.
    final overflows = items.length > itemSlots;
    final visibleSlots =
        overflows ? (itemSlots - 1).clamp(0, itemSlots) : itemSlots;
    final visible = sortedDayItems(items).take(visibleSlots).toList();

    return CalendarDayCellLayout(
      visibleItems: List.unmodifiable(visible),
      overflowCount: items.length - visible.length,
      showsHoliday: holidaySlots > 0,
      showsEvents: maxEvents > 0,
    );
  }

  /// Записи, для которых хватило места, в порядке показа.
  final List<MemoryItem> visibleItems;

  /// Сколько записей не поместилось.
  final int overflowCount;
  final bool showsHoliday;

  /// Помещается ли в ячейку хоть одна строка под содержимое.
  final bool showsEvents;

  bool get showsOverflow => overflowCount > 0;

  /// Высота шапки с числом месяца.
  static const _headerExtent = 30.0;

  /// Высота одной строки содержимого.
  static const _eventSlotExtent = 12.0;

  /// Больше девяти строк ячейка не показывает даже на высоком экране: дальше
  /// это уже не обзор месяца, а список.
  static const _maxEventRows = 9;
}

/// Порядок записей внутри дня: сперва по времени, затем по времени создания.
///
/// Записи без времени идут после тех, у кого оно есть: у них нет места в
/// расписании дня, они просто к нему относятся.
List<MemoryItem> sortedDayItems(List<MemoryItem> source) {
  return [...source]..sort((left, right) {
      final leftTime = left.timeMinutes;
      final rightTime = right.timeMinutes;
      if (leftTime != null && rightTime != null && leftTime != rightTime) {
        return leftTime.compareTo(rightTime);
      }
      if (leftTime != null && rightTime == null) return -1;
      if (leftTime == null && rightTime != null) return 1;
      return left.createdAt.compareTo(right.createdAt);
    });
}
