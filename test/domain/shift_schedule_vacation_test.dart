import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShiftVacation', () {
    test('uses inclusive calendar days across month boundaries', () {
      final vacation = ShiftVacation(
        id: 'august',
        startDate: DateTime(2026, 8, 18),
        durationDays: 14,
      );

      expect(vacation.endDate, DateTime(2026, 8, 31));
      expect(vacation.contains(DateTime(2026, 8, 18, 23, 59)), isTrue);
      expect(vacation.contains(DateTime(2026, 8, 31)), isTrue);
      expect(vacation.contains(DateTime(2026, 9, 1)), isFalse);
    });

    test('handles leap day and overlap without joining adjacent periods', () {
      final leapVacation = ShiftVacation(
        id: 'leap',
        startDate: DateTime(2028, 2, 28),
        durationDays: 3,
      );
      final adjacent = ShiftVacation(
        id: 'adjacent',
        startDate: DateTime(2028, 3, 2),
        durationDays: 2,
      );
      final overlapping = ShiftVacation(
        id: 'overlap',
        startDate: DateTime(2028, 2, 29),
        durationDays: 4,
      );

      expect(leapVacation.endDate, DateTime(2028, 3, 1));
      expect(leapVacation.overlaps(adjacent), isFalse);
      expect(leapVacation.overlaps(overlapping), isTrue);
    });

    test('the schedule shows the running vacation, else the next one', () {
      final past = ShiftVacation(
        id: 'past',
        startDate: DateTime(2026, 1, 5),
        durationDays: 5,
      );
      final running = ShiftVacation(
        id: 'running',
        startDate: DateTime(2026, 8, 20),
        durationDays: 10,
      );
      final future = ShiftVacation(
        id: 'future',
        startDate: DateTime(2026, 12, 1),
        durationDays: 14,
      );
      final schedule = ShiftSchedule(
        id: 'plant',
        organizationName: 'Завод',
        colorValue: 0xFF2F7DD1,
        startDate: DateTime(2026, 1, 1),
        workDays: 2,
        restDays: 2,
        vacations: [past, running, future],
      );

      expect(schedule.vacationToShow(DateTime(2026, 8, 24))?.id, 'running');
      expect(schedule.vacationToShow(DateTime(2026, 9, 1))?.id, 'future');
      expect(schedule.vacationToShow(DateTime(2027, 1, 1)), isNull);
      expect(
        schedule.copyWith(vacations: const []).vacationToShow(
          DateTime(2026, 8, 24),
        ),
        isNull,
      );
    });
  });

  group('ShiftSchedule vacations', () {
    test('mark only original workdays and never shift the cycle', () {
      final schedule = ShiftSchedule(
        id: 'one-three',
        organizationName: 'Завод',
        colorValue: 0xFF2563EB,
        startDate: DateTime(2026, 8, 18),
        workDays: 1,
        restDays: 3,
        vacations: [
          ShiftVacation(
            id: 'summer',
            startDate: DateTime(2026, 8, 18),
            durationDays: 14,
          ),
        ],
      );

      for (final day in [18, 22, 26, 30]) {
        expect(schedule.isWorkday(DateTime(2026, 8, day)), isTrue);
        expect(schedule.isVacationWorkday(DateTime(2026, 8, day)), isTrue);
      }
      expect(schedule.isVacationWorkday(DateTime(2026, 8, 19)), isFalse);
      expect(schedule.isWorkday(DateTime(2026, 9, 3)), isTrue);
      expect(schedule.isVacationWorkday(DateTime(2026, 9, 3)), isFalse);
    });

    test('round trips vacations and loads legacy schedules with none', () {
      final schedule = ShiftSchedule(
        id: 'shift',
        organizationName: 'Work',
        colorValue: 0xFF16A34A,
        startDate: DateTime(2026, 1, 1),
        workDays: 2,
        restDays: 2,
        vacations: [
          ShiftVacation(
            id: 'second',
            startDate: DateTime(2026, 7, 10),
            durationDays: 7,
          ),
          ShiftVacation(
            id: 'first',
            startDate: DateTime(2026, 5, 1),
            durationDays: 14,
          ),
        ],
      );

      final restored = ShiftSchedule.fromJson(schedule.toJson());
      expect(restored.vacations.map((item) => item.id), ['first', 'second']);
      expect(restored.vacations.first.durationDays, 14);

      final legacyJson = Map<String, Object?>.from(schedule.toJson())
        ..remove('vacations');
      expect(ShiftSchedule.fromJson(legacyJson).vacations, isEmpty);
    });
  });
}
