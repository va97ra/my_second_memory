import '../../security/data/encrypted_json_store.dart';
import '../domain/shift_schedule.dart';
import 'shift_schedule_repository.dart';

class EncryptedShiftScheduleRepository implements ShiftScheduleRepository {
  const EncryptedShiftScheduleRepository({
    required this.store,
    required this.plainRepository,
  });

  static const storageKey = 'encrypted_shift_schedules_v1';

  final EncryptedJsonStore store;
  final ShiftScheduleRepository plainRepository;

  @override
  Future<List<ShiftSchedule>> loadSchedules() async {
    if (await store.contains(storageKey)) {
      final decoded = await store.readList(storageKey);
      return decoded.map((entry) {
        return ShiftSchedule.fromJson(Map<String, Object?>.from(entry as Map));
      }).toList();
    }

    final schedules = await plainRepository.loadSchedules();
    await saveSchedules(schedules);
    await plainRepository.saveSchedules(const []);
    return schedules;
  }

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {
    await store.writeList(
      storageKey,
      schedules.map((schedule) => schedule.toJson()).toList(),
    );
  }
}
