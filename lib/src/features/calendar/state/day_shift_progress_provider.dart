import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shift_schedules/shift_schedules.dart';

typedef DayShiftProgress = ({
  ShiftSchedule schedule,
  ProductionProgress progress,
  bool vacation
});

/// Planned shifts relative to the opened date, never the wall clock.
final dayShiftProgressProvider =
    Provider.family<List<DayShiftProgress>, DateTime>((ref, date) {
  return [
    for (final schedule in ref.watch(shiftSchedulesControllerProvider))
      if (schedule.isWorkday(date))
        (
          schedule: schedule,
          vacation: schedule.isVacationWorkday(date),
          progress: workdayProgress(date,
              today: date,
              isWorkingDay: (day) =>
                  schedule.isWorkday(day) && !schedule.isVacationWorkday(day))!
        ),
  ];
});
