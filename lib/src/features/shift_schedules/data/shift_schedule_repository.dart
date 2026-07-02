import '../domain/shift_schedule.dart';

abstract interface class ShiftScheduleRepository {
  Future<List<ShiftSchedule>> loadSchedules();

  Future<void> saveSchedules(List<ShiftSchedule> schedules);
}
