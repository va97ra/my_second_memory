import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_shift_schedule_repository.dart';
import '../data/shift_schedule_repository.dart';
import '../domain/shift_schedule.dart';

final shiftScheduleRepositoryProvider = Provider<ShiftScheduleRepository>(
  (ref) => const LocalShiftScheduleRepository(),
);

final shiftSchedulesControllerProvider =
    StateNotifierProvider<ShiftSchedulesController, List<ShiftSchedule>>((ref) {
  return ShiftSchedulesController(ref.watch(shiftScheduleRepositoryProvider));
});

class ShiftSchedulesController extends StateNotifier<List<ShiftSchedule>> {
  ShiftSchedulesController(this._repository) : super(const []) {
    load();
  }

  final ShiftScheduleRepository _repository;

  Future<void> load() async {
    final schedules = await _repository.loadSchedules();
    state = _sort(schedules);
  }

  Future<void> add(ShiftSchedule schedule) async {
    state = _sort([...state, schedule]);
    await _repository.saveSchedules(state);
  }

  Future<void> update(ShiftSchedule schedule) async {
    state = _sort([
      for (final existing in state)
        if (existing.id == schedule.id) schedule else existing,
    ]);
    await _repository.saveSchedules(state);
  }

  Future<void> toggleEnabled(String id) async {
    state = _sort([
      for (final schedule in state)
        if (schedule.id == id)
          schedule.copyWith(isEnabled: !schedule.isEnabled)
        else
          schedule,
    ]);
    await _repository.saveSchedules(state);
  }

  Future<void> delete(String id) async {
    state = [
      for (final schedule in state)
        if (schedule.id != id) schedule,
    ];
    await _repository.saveSchedules(state);
  }

  Future<void> replaceAll(List<ShiftSchedule> schedules) async {
    state = _sort(schedules);
    await _repository.saveSchedules(state);
  }

  List<ShiftSchedule> workingOn(DateTime date) {
    return [
      for (final schedule in state)
        if (schedule.isWorkday(date)) schedule,
    ];
  }

  List<ShiftSchedule> _sort(List<ShiftSchedule> schedules) {
    return [...schedules]..sort((a, b) {
        final byName = a.organizationName.compareTo(b.organizationName);
        if (byName != 0) {
          return byName;
        }
        return a.startDate.compareTo(b.startDate);
      });
  }
}
