import 'package:flutter_test/flutter_test.dart';
import 'package:my_second_memory/src/features/shift_schedules/domain/shift_schedule.dart';

void main() {
  test('calculates 5/2 schedule', () {
    final schedule = ShiftSchedule(
      id: 'five-two',
      organizationName: 'Работа',
      colorValue: 0xFF2563EB,
      startDate: DateTime(2026, 7, 6),
      workDays: 5,
      restDays: 2,
    );

    expect(schedule.isWorkday(DateTime(2026, 7, 6)), isTrue);
    expect(schedule.isWorkday(DateTime(2026, 7, 10)), isTrue);
    expect(schedule.isWorkday(DateTime(2026, 7, 11)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 12)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 13)), isTrue);
  });

  test('calculates 2/2 schedule', () {
    final schedule = ShiftSchedule(
      id: 'two-two',
      organizationName: 'Смена',
      colorValue: 0xFF16A34A,
      startDate: DateTime(2026, 7, 1),
      workDays: 2,
      restDays: 2,
    );

    expect(schedule.isWorkday(DateTime(2026, 7, 1)), isTrue);
    expect(schedule.isWorkday(DateTime(2026, 7, 2)), isTrue);
    expect(schedule.isWorkday(DateTime(2026, 7, 3)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 4)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 5)), isTrue);
  });

  test('calculates 1/3 day shift schedule', () {
    final schedule = ShiftSchedule(
      id: 'day-three',
      organizationName: 'Сутки',
      colorValue: 0xFFEA580C,
      startDate: DateTime(2026, 7, 1),
      workDays: 1,
      restDays: 3,
    );

    expect(schedule.isWorkday(DateTime(2026, 7, 1)), isTrue);
    expect(schedule.isWorkday(DateTime(2026, 7, 2)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 3)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 4)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 5)), isTrue);
  });

  test('calculates 15/15 rotation schedule', () {
    final schedule = ShiftSchedule(
      id: 'rotation',
      organizationName: 'Вахта',
      colorValue: 0xFF7C3AED,
      startDate: DateTime(2026, 7),
      workDays: 15,
      restDays: 15,
    );

    expect(schedule.isWorkday(DateTime(2026, 7, 1)), isTrue);
    expect(schedule.isWorkday(DateTime(2026, 7, 15)), isTrue);
    expect(schedule.isWorkday(DateTime(2026, 7, 16)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 30)), isFalse);
    expect(schedule.isWorkday(DateTime(2026, 7, 31)), isTrue);
  });

  test('disabled schedule does not mark workdays', () {
    final schedule = ShiftSchedule(
      id: 'disabled',
      organizationName: 'Отключен',
      colorValue: 0xFF475569,
      startDate: DateTime(2026, 7),
      workDays: 5,
      restDays: 2,
      isEnabled: false,
    );

    expect(schedule.isWorkday(DateTime(2026, 7, 1)), isFalse);
  });

  test('serializes and restores schedule', () {
    final schedule = ShiftSchedule(
      id: 'json',
      organizationName: 'Организация',
      colorValue: 0xFF0891B2,
      startDate: DateTime(2026, 7, 3),
      workDays: 7,
      restDays: 7,
      isEnabled: false,
    );

    final restored = ShiftSchedule.fromJson(schedule.toJson());

    expect(restored.id, schedule.id);
    expect(restored.organizationName, schedule.organizationName);
    expect(restored.colorValue, schedule.colorValue);
    expect(restored.startDate, schedule.startDate);
    expect(restored.workDays, schedule.workDays);
    expect(restored.restDays, schedule.restDays);
    expect(restored.isEnabled, isFalse);
  });
}
