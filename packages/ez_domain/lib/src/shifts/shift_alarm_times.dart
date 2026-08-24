import 'shift_presets.dart';
import 'shift_schedule.dart';

/// Когда этот будильник графика должен сработать, начиная с [now].
///
/// Второй будильник звонит на следующий день после рабочего: смена сутки через
/// трое переходит через полночь, и её конец приходится уже на завтра. Момент,
/// который уже прошёл, в список не попадает — будить задним числом нечем.
List<DateTime> shiftAlarmTimes(
  ShiftSchedule schedule,
  ShiftAlarm alarm,
  int slot, {
  required DateTime now,
  int horizonDays = shiftAlarmHorizonDays,
}) {
  if (!schedule.isEnabled || !alarm.isEnabled) return const [];
  if (slot == 1 && !schedule.supportsNextDayAlarm) return const [];

  final lastDay = now.add(Duration(days: horizonDays));
  final times = <DateTime>[];
  for (var day = DateTime(now.year, now.month, now.day);
      !day.isAfter(lastDay);
      day = day.add(const Duration(days: 1))) {
    if (!schedule.isWorkday(day)) continue;
    final alarmDay = slot == 1 ? day.add(const Duration(days: 1)) : day;
    final at = DateTime(
      alarmDay.year,
      alarmDay.month,
      alarmDay.day,
      alarm.timeMinutes ~/ 60,
      alarm.timeMinutes % 60,
    );
    if (at.isAfter(now)) times.add(at);
  }
  return times;
}
