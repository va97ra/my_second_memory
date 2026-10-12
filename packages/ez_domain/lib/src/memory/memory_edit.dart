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
    this.shiftMinutes,
    this.durationMinutes,
    this.title,
    this.addText,
    this.urgent,
    this.reminderBefore,
    this.removeReminder = false,
    this.alarm,
  });

  /// Новый день.
  final DateTime? date;

  /// Новое время начала, минут от полуночи.
  final int? minutes;

  /// Сдвинуть на столько минут: «на час позже» — 60, «на полчаса раньше» —
  /// −30. Через полночь дело переезжает на соседний день.
  final int? shiftMinutes;

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

  /// Будильник: звенит громко в момент напоминания, а без напоминания — в
  /// начале дела. false — снять будильник, тихое напоминание остаётся.
  final bool? alarm;

  bool get isEmpty =>
      date == null &&
      minutes == null &&
      shiftMinutes == null &&
      durationMinutes == null &&
      title == null &&
      addText == null &&
      urgent == null &&
      reminderBefore == null &&
      !removeReminder &&
      alarm == null;
}

/// Запись после правки [edit]. День и время переносятся по правилам
/// переноса ([movedMemoryItem]): напоминание едет вместе с делом.
/// Напоминание в прошлом не ставится — оно не сработало бы молча.
/// Будильник звенит [alarmSound]; нет его или нет времени — не ставится.
MemoryItem editedMemoryItem(
  MemoryItem item,
  RecordEdit edit, {
  required DateTime now,
  ({String uri, String name})? alarmSound,
}) {
  var result = edit.date != null || edit.minutes != null
      ? movedMemoryItem(item, date: edit.date, minutes: edit.minutes, now: now)
      : item.copyWith(updatedAt: now);
  if (edit.shiftMinutes case final shift? when result.timeMinutes != null) {
    final day = result.memoryDate;
    final moment =
        DateTime(day.year, day.month, day.day, 0, result.timeMinutes! + shift);
    result = movedMemoryItem(result,
        date: moment, minutes: moment.hour * 60 + moment.minute, now: now);
  }
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
    result = result.copyWith(clearReminder: true, clearReminderSound: true);
  } else if (edit.reminderBefore case final before? when start != null) {
    final at = reminderMomentOn(result.memoryDate, start)
        .subtract(Duration(minutes: before));
    if (at.isAfter(now)) result = result.copyWith(remindAt: at);
  }
  if (edit.alarm == false) {
    result = result.copyWith(clearReminderSound: true);
  } else if (edit.alarm == true && !edit.removeReminder) {
    final at = result.remindAt ??
        (start == null ? null : reminderMomentOn(result.memoryDate, start));
    if (alarmSound != null && at != null && at.isAfter(now)) {
      result = result.copyWith(
        remindAt: at,
        reminderSoundUri: alarmSound.uri,
        reminderSoundName: alarmSound.name,
      );
    }
  }
  return result;
}
