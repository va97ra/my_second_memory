import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/notifications/data/notification_service.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/data/shift_schedule_repository.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/domain/shift_schedule.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';

void main() {
  test('schedule changes reconcile shift alarms', () async {
    final repository = _ScheduleRepository();
    final alarms = _AlarmScheduler();
    final controller = ShiftSchedulesController(repository, alarms);
    await controller.load();
    final schedule = ShiftSchedule(
      id: 'work',
      organizationName: 'Завод',
      colorValue: 0xFF16A34A,
      startDate: DateTime(2026, 7, 12),
      workDays: 1,
      restDays: 3,
      alarms: const [
        ShiftAlarm(isEnabled: true, timeMinutes: 6 * 60),
        ShiftAlarm(isEnabled: true, timeMinutes: 23 * 60),
      ],
    );

    await controller.add(schedule);
    expect(alarms.last.single.alarms.where((alarm) => alarm.isEnabled),
        hasLength(2));

    await controller.toggleEnabled('work');
    expect(alarms.last.single.isEnabled, isFalse);

    await controller.delete('work');
    expect(alarms.last, isEmpty);
  });
}

class _ScheduleRepository implements ShiftScheduleRepository {
  List<ShiftSchedule> schedules = [];

  @override
  Future<List<ShiftSchedule>> loadSchedules() async => schedules;

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {
    this.schedules = schedules;
  }
}

class _AlarmScheduler implements ShiftAlarmScheduler {
  List<ShiftSchedule> last = [];

  @override
  Future<void> reconcileShiftAlarms(
    List<ShiftSchedule> schedules, {
    bool force = false,
  }) async {
    last = [...schedules];
  }
}
