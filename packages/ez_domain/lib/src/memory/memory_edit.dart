import 'memory_item.dart';
import 'memory_move.dart';
import 'reminder_rules.dart';
import 'styled_text.dart';

/// Что поменять в записи. Всё необязательно: не названо — не трогать.
///
/// Так правит запись нейросеть Джарвиса («перенеси врача на час позже,
/// напомни за час и допиши: взять полис») — одной правкой с одной отменой.
class RecordEdit {
  const RecordEdit({
    this.date,
    this.minutes,
    this.durationMinutes,
    this.title,
    this.addText,
    this.urgent,
    this.reminderBefore,
    this.removeReminder = false,
  });

  /// Новый день.
  final DateTime? date;

  /// Новое время начала, минут от полуночи.
  final int? minutes;

  /// Сколько займёт: конец — начало плюс столько.
  final int? durationMinutes;

  final String? title;

  /// Дописать в текст записи новой строкой.
  final String? addText;

  /// Срочное — важность записи.
  final bool? urgent;

  /// Напомнить за столько минут до начала; 0 — в момент начала.
  final int? reminderBefore;
  final bool removeReminder;

  bool get isEmpty =>
      date == null &&
      minutes == null &&
      durationMinutes == null &&
      title == null &&
      addText == null &&
      urgent == null &&
      reminderBefore == null &&
      !removeReminder;
}

/// Запись после правки [edit]. День и время переносятся по правилам
/// переноса ([movedMemoryItem]): напоминание едет вместе с делом.
/// Напоминание в прошлом не ставится — оно не сработало бы молча.
MemoryItem editedMemoryItem(
  MemoryItem item,
  RecordEdit edit, {
  required DateTime now,
}) {
  var result = edit.date != null || edit.minutes != null
      ? movedMemoryItem(item, date: edit.date, minutes: edit.minutes, now: now)
      : item.copyWith(updatedAt: now);
  final start = result.timeMinutes;
  if (edit.durationMinutes case final length? when start != null) {
    result =
        result.copyWith(endMinutes: (start + length).clamp(start, 24 * 60 - 1));
  }
  if (edit.title case final title?) result = result.copyWith(title: title);
  if (edit.addText case final text?) {
    final body = StyledText.parse(result.body);
    final added = body.plain.trim().isEmpty ? text : '\n$text';
    result = result.copyWith(body: body.appended(added).toStored());
  }
  if (edit.urgent case final urgent?) {
    result = result.copyWith(priority: urgent ? 1 : 0);
  }
  if (edit.removeReminder) {
    result = result.copyWith(clearReminder: true);
  } else if (edit.reminderBefore case final before? when start != null) {
    final at = reminderMomentOn(result.memoryDate, start)
        .subtract(Duration(minutes: before));
    if (at.isAfter(now)) result = result.copyWith(remindAt: at);
  }
  return result;
}
