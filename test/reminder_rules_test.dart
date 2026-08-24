import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

MemoryItem _item({
  MemoryStatus status = MemoryStatus.active,
  DateTime? remindAt,
  String? seriesId,
  bool isGeneratedOccurrence = false,
}) {
  final date = DateTime(2026, 5, 20);
  return MemoryItem(
    id: 'item',
    type: MemoryType.task,
    title: 'Запись',
    body: 'Запись',
    memoryDate: date,
    createdAt: date,
    updatedAt: date,
    status: status,
    remindAt: remindAt,
    seriesId: seriesId,
    isGeneratedOccurrence: isGeneratedOccurrence,
  );
}

void main() {
  final now = DateTime(2026, 5, 20, 12);

  test('a live record with a future reminder wants one', () {
    expect(
      wantsReminder(_item(remindAt: now.add(const Duration(hours: 1))),
          now: now),
      isTrue,
    );
  });

  test('a reminder in the past is not waiting to happen', () {
    expect(
      wantsReminder(_item(remindAt: now.subtract(const Duration(minutes: 1))),
          now: now),
      isFalse,
    );
  });

  test('done and archived records stop reminding', () {
    for (final status in [MemoryStatus.done, MemoryStatus.archived]) {
      expect(
        wantsReminder(
          _item(status: status, remindAt: now.add(const Duration(hours: 1))),
          now: now,
        ),
        isFalse,
        reason: 'status $status should not remind',
      );
    }
  });

  test('a record without a reminder wants nothing', () {
    expect(wantsReminder(_item(), now: now), isFalse);
  });

  test('only a projected occurrence counts as a recurrence reminder', () {
    // Запись, ставшая шаблоном серии, согласуется вместе с обычными: у неё
    // есть seriesId, но она не проекция.
    expect(
      ReminderSource.of(_item(seriesId: 'series')),
      ReminderSource.memory,
    );
    expect(
      ReminderSource.of(
        _item(seriesId: 'series', isGeneratedOccurrence: true),
      ),
      ReminderSource.recurrence,
    );
    expect(ReminderSource.of(_item()), ReminderSource.memory);
  });

  group('Момент напоминания', () {
    final day = DateTime(2026, 8, 24);

    test('считается временем суток на дне записи', () {
      expect(reminderMomentOn(day, 7 * 60 + 30), DateTime(2026, 8, 24, 7, 30));
    });

    test('без времени напоминать нечем', () {
      expect(canRemindAt(day, null, now: DateTime(2026, 8, 24, 6)), isFalse);
    });

    test('прошедший момент не наступит', () {
      final now = DateTime(2026, 8, 24, 9);
      expect(canRemindAt(day, 8 * 60, now: now), isFalse);
      expect(canRemindAt(day, 10 * 60, now: now), isTrue);
    });
  });
}
