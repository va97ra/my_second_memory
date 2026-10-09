import 'shift_schedule.dart';

/// По каким включённым графикам день рабочий. Отпуск — не рабочий день.
///
/// Одно правило на всё: им отвечает Джарвис («я завтра работаю?») и им же
/// строятся сводки.
List<String> workingShifts(Iterable<ShiftSchedule> schedules, DateTime day) => [
      for (final schedule in schedules)
        if (schedule.isEnabled &&
            schedule.isWorkday(day) &&
            !schedule.isVacationWorkday(day))
          schedule.organizationName,
    ];
