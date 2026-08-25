import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

ShiftSchedule _schedule({
  required int workDays,
  required int restDays,
  required List<ShiftAlarm> alarms,
  bool isEnabled = true,
  DateTime? start,
}) {
  final startDate = start ?? DateTime(2026, 8, 24);
  return ShiftSchedule(
    id: 'plant',
    organizationName: 'Завод',
    colorValue: 0xFF2F7DD1,
    startDate: startDate,
    workDays: workDays,
    restDays: restDays,
    isEnabled: isEnabled,
    alarms: alarms,
  );
}

void main() {
  final now = DateTime(2026, 8, 24, 6);
  const morning = ShiftAlarm(isEnabled: true, timeMinutes: 7 * 60);

  test('будильник ставится только на рабочие дни', () {
    final schedule = _schedule(
      workDays: 2,
      restDays: 2,
      alarms: const [morning, ShiftAlarm()],
    );

    final times =
        shiftAlarmTimes(schedule, morning, 0, now: now, horizonDays: 5);

    expect(times, [
      DateTime(2026, 8, 24, 7),
      DateTime(2026, 8, 25, 7),
      DateTime(2026, 8, 28, 7),
      DateTime(2026, 8, 29, 7),
    ]);
  });

  test('прошедшее время сегодня не попадает в список', () {
    final schedule = _schedule(
      workDays: 5,
      restDays: 2,
      alarms: const [morning, ShiftAlarm()],
    );

    final times = shiftAlarmTimes(
      schedule,
      morning,
      0,
      now: DateTime(2026, 8, 24, 8),
      horizonDays: 1,
    );

    expect(times, [DateTime(2026, 8, 25, 7)]);
  });

  test('второй будильник звонит на следующий день и только у суток через трое',
      () {
    const evening = ShiftAlarm(isEnabled: true, timeMinutes: 20 * 60);
    final nextDay = _schedule(
      workDays: 1,
      restDays: 3,
      alarms: const [morning, evening],
    );
    final plain = _schedule(
      workDays: 2,
      restDays: 2,
      alarms: const [morning, evening],
    );

    expect(
      shiftAlarmTimes(nextDay, evening, 1, now: now, horizonDays: 5),
      [DateTime(2026, 8, 25, 20), DateTime(2026, 8, 29, 20)],
    );
    expect(
        shiftAlarmTimes(plain, evening, 1, now: now, horizonDays: 5), isEmpty);
  });

  test('выключенный график и выключенный будильник молчат', () {
    const off = ShiftAlarm(timeMinutes: 7 * 60);
    final disabled = _schedule(
      workDays: 5,
      restDays: 2,
      alarms: const [morning, ShiftAlarm()],
      isEnabled: false,
    );
    final enabled = _schedule(
      workDays: 5,
      restDays: 2,
      alarms: const [off, ShiftAlarm()],
    );

    expect(shiftAlarmTimes(disabled, morning, 0, now: now), isEmpty);
    expect(shiftAlarmTimes(enabled, off, 0, now: now), isEmpty);
  });
}
