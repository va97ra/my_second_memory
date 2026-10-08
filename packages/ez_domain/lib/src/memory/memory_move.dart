import 'memory_item.dart';
import 'reminder_rules.dart';

/// Запись, перенесённая на другой день или время.
///
/// Напоминание едет вместе с делом и сохраняет свой зазор: напоминание «за
/// час до встречи» после переноса остаётся за час до неё. Длительность дела
/// тоже сохраняется. Напоминание, оказавшееся в прошлом, снимается: оно не
/// сработает, и человек об этом не узнает.
MemoryItem movedMemoryItem(
  MemoryItem item, {
  DateTime? date,
  int? minutes,
  required DateTime now,
}) {
  final day = date == null
      ? item.memoryDate
      : DateTime(date.year, date.month, date.day);
  final start = minutes ?? item.timeMinutes;
  final oldStart = item.timeMinutes;
  final oldEnd = item.endMinutes;
  int? end;
  if (start != null && oldStart != null && oldEnd != null) {
    // Дело, уехавшее за полночь, кончается в конце своего дня: шкала дня
    // не переходит на следующий.
    end = (start + (oldEnd - oldStart)).clamp(start, 24 * 60 - 1);
  }

  final oldMoment = reminderMomentOn(item.memoryDate, oldStart ?? 0);
  final newMoment = reminderMomentOn(day, start ?? 0);
  final reminder = item.remindAt?.add(newMoment.difference(oldMoment));
  final keptReminder = reminder != null && reminder.isAfter(now) ? reminder : null;

  return item.copyWith(
    memoryDate: day,
    timeMinutes: start,
    endMinutes: end,
    clearTime: start == null,
    remindAt: keptReminder,
    clearReminder: keptReminder == null,
    isUndated: false,
    updatedAt: now,
  );
}
