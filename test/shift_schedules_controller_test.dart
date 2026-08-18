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

  test('existing duplicate schedules are collapsed during load', () async {
    final older = DateTime(2026, 8, 18, 10);
    final newer = DateTime(2026, 8, 18, 11);
    final repository = _ScheduleRepository()
      ..schedules = [
        ShiftSchedule(
          id: 'windows-copy',
          organizationName: 'СВ Консалтинг',
          colorValue: 0xFF1976D2,
          startDate: DateTime(2026, 8, 2),
          workDays: 1,
          restDays: 3,
          updatedAt: older,
        ),
        ShiftSchedule(
          id: 'android-copy',
          organizationName: '  св   консалтинг ',
          colorValue: 0xFF1976D2,
          startDate: DateTime(2026, 8, 6),
          workDays: 1,
          restDays: 3,
          alarms: const [
            ShiftAlarm(isEnabled: true, timeMinutes: 8 * 60),
            ShiftAlarm(),
          ],
          vacations: [
            ShiftVacation(
              id: 'newer-vacation',
              startDate: DateTime(2026, 8, 18),
              durationDays: 14,
            ),
          ],
          updatedAt: newer,
        ),
      ];

    final controller = ShiftSchedulesController(repository);
    await controller.load();

    expect(controller.state, hasLength(1));
    expect(controller.state.single.id, 'android-copy');
    expect(controller.state.single.colorValue, 0xFF1976D2);
    expect(controller.state.single.vacations.single.durationDays, 14);
    expect(repository.schedules, hasLength(1));
  });

  test('similar schedules with a real difference are both preserved', () async {
    final repository = _ScheduleRepository()
      ..schedules = [
        ShiftSchedule(
          id: 'blue',
          organizationName: 'Работа',
          colorValue: 0xFF1976D2,
          startDate: DateTime(2026, 8, 2),
          workDays: 1,
          restDays: 3,
          updatedAt: DateTime(2026, 8, 18, 10),
        ),
        ShiftSchedule(
          id: 'red',
          organizationName: 'Работа',
          colorValue: 0xFFE53935,
          startDate: DateTime(2026, 8, 2),
          workDays: 1,
          restDays: 3,
          updatedAt: DateTime(2026, 8, 18, 11),
        ),
      ];

    final controller = ShiftSchedulesController(repository);
    await controller.load();

    expect(controller.state, hasLength(2));
    expect(repository.schedules, hasLength(2));
  });

  test('unrelated names keep otherwise matching calendars separate', () async {
    final repository = _ScheduleRepository()
      ..schedules = [
        ShiftSchedule(
          id: 'main-work',
          organizationName: 'Основная работа',
          colorValue: 0xFF1976D2,
          startDate: DateTime(2026, 8, 2),
          workDays: 1,
          restDays: 3,
          updatedAt: DateTime(2026, 8, 18, 10),
        ),
        ShiftSchedule(
          id: 'side-work',
          organizationName: 'Подработка',
          colorValue: 0xFF1976D2,
          startDate: DateTime(2026, 8, 6),
          workDays: 1,
          restDays: 3,
          updatedAt: DateTime(2026, 8, 18, 11),
        ),
      ];

    final controller = ShiftSchedulesController(repository);
    await controller.load();

    expect(controller.state, hasLength(2));
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
