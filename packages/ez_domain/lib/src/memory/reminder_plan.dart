import 'dart:convert';

import 'memory_item.dart';
import 'reminder_rules.dart';

/// Уведомление, которое уже стоит в расписании платформы.
///
/// Всё, кроме [notificationId], прочитано из payload и может отсутствовать:
/// уведомления ставились и прошлыми версиями приложения.
final class PendingReminder {
  const PendingReminder({
    required this.notificationId,
    this.source,
    this.fingerprint,
  });

  final int notificationId;
  final String? source;
  final int? fingerprint;
}

/// Что сделать с расписанием одного источника, чтобы оно совпало с записями.
final class ReminderPlan {
  const ReminderPlan({required this.cancel, required this.schedule});

  /// Уведомления, которым больше незачем звучать.
  final List<int> cancel;

  /// Записи, чьё напоминание нужно поставить заново.
  final List<MemoryItem> schedule;
}

/// Сводит расписание одного источника со списком записей.
///
/// Стоящее уведомление верно, только пока совпадает его отпечаток: id
/// записи после правки времени, текста или мелодии остаётся прежним, и
/// сверка по одному id оставила бы напоминание звучать по-старому. У
/// уведомлений прошлых версий отпечатка нет, они переставляются один раз.
///
/// Чужой источник не трогается: обычные записи и вхождения повторов
/// согласуются отдельно и не должны отменять напоминания друг друга.
ReminderPlan planReminders({
  required String source,
  required Iterable<MemoryItem> items,
  required Iterable<PendingReminder> pending,
  DateTime? now,
}) {
  final wanted = {
    for (final item in items)
      if (ReminderSource.of(item) == source && wantsReminder(item, now: now))
        stableNotificationId(item.id): item,
  };
  final current = <int>{};
  final cancel = <int>[];
  for (final reminder in pending) {
    if (reminder.source != source) continue;
    final item = wanted[reminder.notificationId];
    if (item == null) {
      cancel.add(reminder.notificationId);
    } else if (reminder.fingerprint == reminderFingerprint(item)) {
      current.add(reminder.notificationId);
    }
  }
  return ReminderPlan(
    cancel: cancel,
    schedule: [
      for (final MapEntry(key: id, value: item) in wanted.entries)
        if (!current.contains(id)) item,
    ],
  );
}

/// Отпечаток напоминания: всё, что человек увидит и услышит, когда оно
/// сработает. Стоящее уведомление с другим отпечатком устарело.
int reminderFingerprint(MemoryItem item) => stableNotificationId(
      [
        item.remindAt?.toIso8601String() ?? '',
        item.title,
        item.plainBody,
        item.reminderSoundUri ?? '',
        item.reminderSoundName ?? '',
      ].join('\u0000'),
    );

/// Неотрицательное 31-битное число, одно и то же для одной строки на любом
/// устройстве и при любом запуске (FNV-1a по байтам UTF-8).
int stableNotificationId(String value) {
  var hash = 0x811C9DC5;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}
