import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Правка записи одной командой: так её правит нейросеть Джарвиса.
void main() {
  final now = DateTime(2099, 10, 7, 14);
  final doctor = MemoryItem(
    id: 'doctor',
    type: MemoryType.task,
    title: 'Врач',
    body: 'Куда: Ленина, 5',
    memoryDate: DateTime(2099, 10, 8),
    timeMinutes: 10 * 60,
    endMinutes: 10 * 60 + 30,
    remindAt: DateTime(2099, 10, 8, 9),
    createdAt: now,
    updatedAt: now,
  );

  test('пусто — ничего не меняется', () {
    expect(const RecordEdit().isEmpty, isTrue);
    final same = editedMemoryItem(doctor, const RecordEdit(), now: now);
    expect((same.memoryDate, same.timeMinutes, same.body),
        (doctor.memoryDate, doctor.timeMinutes, doctor.body));
  });

  test('будильник — звук телефона в момент напоминания, снять — тише', () {
    const sound = (uri: 'content://alarm', name: 'Будильник телефона');
    final loud = editedMemoryItem(doctor, const RecordEdit(alarm: true),
        now: now, alarmSound: sound);
    expect((loud.remindAt, loud.reminderSoundUri),
        (DateTime(2099, 10, 8, 9), 'content://alarm'));
    final quiet =
        editedMemoryItem(loud, const RecordEdit(alarm: false), now: now);
    expect((quiet.remindAt, quiet.reminderSoundUri),
        (DateTime(2099, 10, 8, 9), null));
    // Без напоминания будильник звенит к началу дела; без времени — никак.
    final bare = doctor.copyWith(clearReminder: true);
    expect(
        editedMemoryItem(bare, const RecordEdit(alarm: true),
                now: now, alarmSound: sound)
            .remindAt,
        DateTime(2099, 10, 8, 10));
    final allDay = bare.copyWith(clearTime: true);
    expect(
        editedMemoryItem(allDay, const RecordEdit(alarm: true),
                now: now, alarmSound: sound)
            .reminderSoundUri,
        isNull);
  });

  test('перенос — напоминание едет вместе с делом', () {
    final moved =
        editedMemoryItem(doctor, const RecordEdit(minutes: 11 * 60), now: now);
    expect(moved.timeMinutes, 11 * 60);
    expect(moved.endMinutes, 11 * 60 + 30);
    expect(moved.remindAt, DateTime(2099, 10, 8, 10));
  });

  test('длительность, название, срочность, напоминание', () {
    final edited = editedMemoryItem(
      doctor,
      const RecordEdit(
        durationMinutes: 120,
        title: 'Стоматолог',
        urgent: true,
        reminderBefore: 60,
      ),
      now: now,
    );
    expect(edited.endMinutes, 12 * 60);
    expect(edited.title, 'Стоматолог');
    expect(edited.priority, 1);
    expect(edited.remindAt, DateTime(2099, 10, 8, 9));
    expect(
        editedMemoryItem(doctor, const RecordEdit(removeReminder: true),
                now: now)
            .remindAt,
        isNull);
  });

  test('дописать — новой строкой, оформление написанного цело', () {
    final appended = editedMemoryItem(
        doctor, const RecordEdit(addText: 'Взять полис'),
        now: now);
    expect(appended.plainBody, 'Куда: Ленина, 5\nВзять полис');
    final bold = StyledText('Куда', List.filled(4, const TextMark(bold: true)));
    final styled = doctor.copyWith(body: bold.toStored());
    final kept = StyledText.parse(
        editedMemoryItem(styled, const RecordEdit(addText: 'Полис'), now: now)
            .body);
    expect(kept.plain, 'Куда\nПолис');
    expect(kept.runs().single.mark.bold, isTrue,
        reason: 'жирное осталось жирным, дописанное — простым');
  });

  test('напоминание в прошлом не ставится', () {
    final past = editedMemoryItem(
      doctor.copyWith(memoryDate: DateTime(2099, 10, 7), clearReminder: true),
      const RecordEdit(reminderBefore: 600),
      now: now,
    );
    expect(past.remindAt, isNull);
  });
}
