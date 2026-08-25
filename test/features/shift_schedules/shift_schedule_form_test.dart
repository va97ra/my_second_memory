import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedule_form.dart';
import 'package:flutter_test/flutter_test.dart';

const _nextDayPreset = ShiftPreset(
  key: '1/3',
  ruLabel: 'сутки/трое',
  enLabel: '24h/3 off',
  workDays: 1,
  restDays: 3,
);

const _fiveTwoPreset = ShiftPreset(
  key: '5/2',
  ruLabel: '5/2',
  enLabel: '5/2',
  workDays: 5,
  restDays: 2,
);

ShiftScheduleForm _formWithBothAlarms() {
  return ShiftScheduleForm.blank(DateTime(2026, 8, 24)).withAlarms(
    const [
      ShiftAlarm(isEnabled: true, timeMinutes: 7 * 60),
      ShiftAlarm(isEnabled: true, timeMinutes: 8 * 60),
    ],
  );
}

void main() {
  group('ShiftScheduleForm', () {
    test('blank form starts on a ready pattern and hides manual input', () {
      final form = ShiftScheduleForm.blank(DateTime(2026, 8, 24, 18, 30));

      expect(form.presetKey, '5/2');
      expect(form.showManualSchedule, isFalse);
      expect(form.startDate, DateTime(2026, 8, 24));
      expect(form.alarms, hasLength(shiftAlarmSlots));
      expect(form.vacations, isEmpty);
    });

    test('a pattern outside the ready ones opens manual input', () {
      final form = ShiftScheduleForm.fromSchedule(
        ShiftSchedule(
          id: 'manual',
          organizationName: 'Завод',
          colorValue: 0xFF000000,
          startDate: DateTime(2026, 1, 5),
          workDays: 3,
          restDays: 1,
        ),
      );

      expect(form.presetKey, isNull);
      expect(form.showManualSchedule, isTrue);
    });

    test('days that stop matching a pattern drop the selection', () {
      final form = ShiftScheduleForm.blank(DateTime(2026, 8, 24));

      expect(form.withDays(3, 1).presetKey, isNull);
      expect(form.withDays(null, 2).presetKey, isNull);
      expect(form.withDays(1, 3).presetKey, '1/3');
    });

    test('the next-day alarm survives only the pattern that allows it', () {
      final form = _formWithBothAlarms();

      expect(form.withPreset(_nextDayPreset).alarms[1].isEnabled, isTrue);
      expect(form.withPreset(_fiveTwoPreset).alarms[1].isEnabled, isFalse);
      expect(form.withDays(1, 3).alarms[1].isEnabled, isTrue);
      expect(form.withDays(2, 2).alarms[1].isEnabled, isFalse);
      expect(form.withDays(null, null).alarms[1].isEnabled, isFalse);
    });

    test('opening manual input drops the selected pattern', () {
      final form = ShiftScheduleForm.blank(DateTime(2026, 8, 24));
      final manual = form.toggleManualSchedule();

      expect(manual.showManualSchedule, isTrue);
      expect(manual.presetKey, isNull);
      expect(manual.toggleManualSchedule().showManualSchedule, isFalse);
    });

    test('vacations stay ordered by their start', () {
      final august = ShiftVacation(
        id: 'august',
        startDate: DateTime(2026, 8, 10),
        durationDays: 7,
      );
      final may = ShiftVacation(
        id: 'may',
        startDate: DateTime(2026, 5, 1),
        durationDays: 3,
      );

      final form = ShiftScheduleForm.blank(DateTime(2026, 1, 1))
          .withVacation(august)
          .withVacation(may);

      expect(form.vacations.map((vacation) => vacation.id), ['may', 'august']);
      expect(form.withoutVacation('may').vacations.single.id, 'august');
    });

    test('an unfilled form saves nothing', () {
      final form = ShiftScheduleForm.blank(DateTime(2026, 8, 24));

      expect(
        form.toSchedule(
          id: null,
          organizationName: '   ',
          workDays: 5,
          restDays: 2,
        ),
        isNull,
      );
      expect(
        form.toSchedule(
          id: null,
          organizationName: 'Завод',
          workDays: 0,
          restDays: 2,
        ),
        isNull,
      );
      expect(
        form.toSchedule(
          id: null,
          organizationName: 'Завод',
          workDays: 5,
          restDays: null,
        ),
        isNull,
      );
    });

    test('saving keeps the id and silences an alarm the pattern lost', () {
      final schedule = _formWithBothAlarms().toSchedule(
        id: 'existing',
        organizationName: '  Завод  ',
        workDays: 5,
        restDays: 2,
      );

      expect(schedule, isNotNull);
      expect(schedule!.id, 'existing');
      expect(schedule.organizationName, 'Завод');
      expect(schedule.workDays, 5);
      expect(schedule.alarms.first.isEnabled, isTrue);
      expect(schedule.alarms[1].isEnabled, isFalse);
      expect(schedule.startDate, DateTime(2026, 8, 24));
    });
  });
}
