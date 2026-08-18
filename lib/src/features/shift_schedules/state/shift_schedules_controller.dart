import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/data/encrypted_json_store.dart';
import '../../security/state/security_provider.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../notifications/data/notification_service.dart';
import '../../sync/domain/sync_mutation_observer.dart';
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
    ref.watch(syncMutationObserverProvider),
  );
});

class ShiftSchedulesController extends StateNotifier<List<ShiftSchedule>> {
  ShiftSchedulesController(this._repository, [this._alarms, this._sync])
      : super(const []) {
    _loadFuture = _load();
  }

  final ShiftScheduleRepository _repository;
  final ShiftAlarmScheduler? _alarms;
  final SyncMutationObserver? _sync;
  late final Future<void> _loadFuture;

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    final storedSchedules = await _repository.loadSchedules();
    final now = DateTime.now();
    final needsTimestampMigration =
        storedSchedules.any((schedule) => schedule.updatedAt == null);
    final schedules = [
      for (final schedule in storedSchedules)
        if (schedule.updatedAt == null)
          schedule.copyWith(updatedAt: now)
        else
          schedule,
    ];
    if (needsTimestampMigration) {
      await _repository.saveSchedules(schedules);
    }
    state = _sort(schedules);
    unawaited(_safeReconcileAlarms());
  }

  Future<void> add(ShiftSchedule schedule) async {
    await _loadFuture;
    state = _sort([...state, schedule.copyWith(updatedAt: DateTime.now())]);
    await _repository.saveSchedules(state);
    _sync?.shiftSchedulesChanged();
    await _safeReconcileAlarms(force: true);
  }

  Future<void> update(ShiftSchedule schedule) async {
    await _loadFuture;
    final updated = schedule.copyWith(updatedAt: DateTime.now());
    state = _sort([
      for (final existing in state)
        if (existing.id == schedule.id) updated else existing,
    ]);
    await _repository.saveSchedules(state);
    _sync?.shiftSchedulesChanged();
    await _safeReconcileAlarms(force: true);
  }

  Future<void> toggleEnabled(String id) async {
    await _loadFuture;
    final now = DateTime.now();
    state = _sort([
      for (final schedule in state)
        if (schedule.id == id)
          schedule.copyWith(
            isEnabled: !schedule.isEnabled,
            updatedAt: now,
          )
        else
          schedule,
    ]);
    await _repository.saveSchedules(state);
    _sync?.shiftSchedulesChanged();
    await _safeReconcileAlarms(force: true);
  }

  Future<void> delete(String id) async {
    await _loadFuture;
    final deletedAt = DateTime.now();
    state = [
      for (final schedule in state)
        if (schedule.id != id) schedule,
    ];
    await _repository.saveSchedules(state);
    await _sync?.shiftScheduleDeleted(id, deletedAt);
    await _safeReconcileAlarms(force: true);
  }

  Future<void> replaceAll(List<ShiftSchedule> schedules) async {
    await _loadFuture;
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
