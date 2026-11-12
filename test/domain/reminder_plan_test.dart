import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 12, 9);

MemoryItem _item({
  String id = 'record',
  DateTime? remindAt,
  String body = 'Оплатить связь',
  String? soundUri,
  bool occurrence = false,
}) {
  final day = DateTime(2026, 11, 20);
  return MemoryItem(
    id: id,
    type: MemoryType.task,
    title: body,
    body: body,
    memoryDate: day,
    createdAt: day,
    updatedAt: day,
    remindAt: remindAt ?? DateTime(2026, 11, 20, 10),
    reminderSoundUri: soundUri,
    seriesId: occurrence ? 'series' : null,
    isGeneratedOccurrence: occurrence,
  );
}

/// Уведомление, поставленное по записи в её прежнем виде.
PendingReminder _scheduledFor(MemoryItem item) => PendingReminder(
      notificationId: stableNotificationId(item.id),
      source: ReminderSource.of(item),
      fingerprint: reminderFingerprint(item),
    );

ReminderPlan _plan(
        String source, List<MemoryItem> items, List<PendingReminder> pending) =>
    planReminders(source: source, items: items, pending: pending, now: _now);

void main() {
  test('an unchanged reminder is left alone', () {
    final item = _item();
    final plan = _plan(ReminderSource.memory, [item], [_scheduledFor(item)]);

    expect(plan.cancel, isEmpty);
    expect(plan.schedule, isEmpty);
  });

  test('a missing reminder is scheduled', () {
    final item = _item();
    final plan = _plan(ReminderSource.memory, [item], const []);

    expect(plan.schedule, [item]);
  });

  test('an occurrence moved to another time is rescheduled', () {
    // Б1: ежемесячная запись на 10:00, вхождение перенесли на 12:00.
    final before = _item(id: 'series_20261120', occurrence: true);
    final after = _item(
      id: 'series_20261120',
      occurrence: true,
      remindAt: DateTime(2026, 11, 20, 12),
    );
    final plan = _plan(
      ReminderSource.recurrence,
      [after],
      [_scheduledFor(before)],
    );

    expect(plan.schedule, [after]);
  });

  test('a record changed by sync is rescheduled', () {
    // Запись пришла с другого устройства с новым временем и текстом, а
    // уведомление по старой версии всё ещё стоит.
    final before = _item();
    final after = _item(
      body: 'Оплатить связь и интернет',
      remindAt: DateTime(2026, 11, 20, 18),
    );
    final plan = _plan(ReminderSource.memory, [after], [_scheduledFor(before)]);

    expect(plan.schedule, [after]);
  });

  test('a new melody reschedules the reminder', () {
    final before = _item();
    final after = _item(soundUri: 'content://media/alarm/7');
    final plan = _plan(ReminderSource.memory, [after], [_scheduledFor(before)]);

    expect(plan.schedule, [after]);
  });

  test('a reminder from an older version without fingerprint is renewed', () {
    final item = _item();
    final plan = _plan(ReminderSource.memory, [
      item
    ], [
      PendingReminder(
        notificationId: stableNotificationId(item.id),
        source: ReminderSource.memory,
      ),
    ]);

    expect(plan.schedule, [item]);
  });

  test('a reminder nobody wants any more is cancelled', () {
    final gone = _item(id: 'deleted');
    final past = _item(id: 'past', remindAt: DateTime(2026, 11, 1, 10));
    final plan = _plan(
      ReminderSource.memory,
      [past],
      [_scheduledFor(gone), _scheduledFor(past)],
    );

    expect(plan.cancel, [
      stableNotificationId('deleted'),
      stableNotificationId('past'),
    ]);
    expect(plan.schedule, isEmpty);
  });

  test("another source's reminders are not touched", () {
    final occurrence = _item(id: 'series_20261120', occurrence: true);
    final plan = _plan(ReminderSource.memory, const [], [
      _scheduledFor(occurrence),
      const PendingReminder(notificationId: 7, source: 'shift_alarm'),
    ]);

    expect(plan.cancel, isEmpty);
  });

  test('notification ids are stable, positive and record-specific', () {
    final first = stableNotificationId('record-1');

    expect(first, stableNotificationId('record-1'));
    expect(first, greaterThanOrEqualTo(0));
    expect(first, isNot(stableNotificationId('record-2')));
  });
}
