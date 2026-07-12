import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/data/encrypted_json_store.dart';
import '../../security/state/security_provider.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../notifications/data/notification_service.dart';
import '../data/encrypted_shift_schedule_repository.dart';
import '../data/local_shift_schedule_repository.dart';
import '../data/shift_schedule_repository.dart';
import '../domain/shift_schedule.dart';

final shiftScheduleRepositoryProvider =
    Provider<ShiftScheduleRepository>((ref) {
  const plainRepository = LocalShiftScheduleRepository();
  final session = ref.watch(securitySessionProvider);
  final cipher = session.cipher;
  if (session.hasPin && cipher != null) {
    final memoryRepository = ref.watch(plainMemoryRepositoryProvider);
    return EncryptedShiftScheduleRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: plainRepository,
      backend: memoryRepository is SecureEntityBackend
          ? memoryRepository as SecureEntityBackend
          : null,
    );
  }
  return plainRepository;
});

final shiftSchedulesControllerProvider =
    StateNotifierProvider<ShiftSchedulesController, List<ShiftSchedule>>((ref) {
  return ShiftSchedulesController(
    ref.watch(shiftScheduleRepositoryProvider),
    ref.watch(shiftAlarmSchedulerProvider),
  );
});

class ShiftSchedulesController extends StateNotifier<List<ShiftSchedule>> {
  ShiftSchedulesController(this._repository, [this._alarms]) : super(const []) {
    load();
  }

  final ShiftScheduleRepository _repository;
  final ShiftAlarmScheduler? _alarms;

  Future<void> load() async {
    final schedules = await _repository.loadSchedules();
    state = _sort(schedules);
    await _safeReconcileAlarms();
  }

  Future<void> add(ShiftSchedule schedule) async {
    state = _sort([...state, schedule]);
    await _repository.saveSchedules(state);
    await _safeReconcileAlarms(force: true);
  }

  Future<void> update(ShiftSchedule schedule) async {
    state = _sort([
      for (final existing in state)
        if (existing.id == schedule.id) schedule else existing,
    ]);
    await _repository.saveSchedules(state);
    await _safeReconcileAlarms(force: true);
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
    await _safeReconcileAlarms(force: true);
  }

  Future<void> delete(String id) async {
    state = [
      for (final schedule in state)
        if (schedule.id != id) schedule,
    ];
    await _repository.saveSchedules(state);
    await _safeReconcileAlarms(force: true);
  }

  Future<void> replaceAll(List<ShiftSchedule> schedules) async {
    state = _sort(schedules);
    await _repository.saveSchedules(state);
    await _safeReconcileAlarms(force: true);
  }

  List<ShiftSchedule> workingOn(DateTime date) {
    return [
      for (final schedule in state)
        if (schedule.isWorkday(date)) schedule,
    ];
  }

  Future<void> _safeReconcileAlarms({bool force = false}) async {
    try {
      await _alarms?.reconcileShiftAlarms(state, force: force);
    } catch (_) {
      // The schedule remains saved if Android rejects an exact alarm.
    }
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
