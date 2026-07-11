import '../../security/data/encrypted_json_store.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../security/data/secure_entity_codec.dart';
import '../domain/shift_schedule.dart';
import 'shift_schedule_repository.dart';

class EncryptedShiftScheduleRepository implements ShiftScheduleRepository {
  const EncryptedShiftScheduleRepository({
    required this.store,
    required this.plainRepository,
    this.backend,
  });

  static const storageKey = 'encrypted_shift_schedules_v1';
  static const entityKind = 'shift_schedule';

  final EncryptedJsonStore store;
  final ShiftScheduleRepository plainRepository;
  final SecureEntityBackend? backend;

  @override
  Future<List<ShiftSchedule>> loadSchedules() async {
    final secureBackend = backend;
    if (secureBackend != null) {
      var rows = await secureBackend.loadSecureEntities(entityKind);
      if (rows.isEmpty) {
        final schedules = await _loadLegacyOrPlain();
        await _replaceRows(schedules);
        rows = await secureBackend.loadSecureEntities(entityKind);
        final verified = await _decodeRows(rows);
        if (verified.length != schedules.length) {
          throw StateError('Encrypted shift migration verification failed');
        }
        await store.remove(storageKey);
        await plainRepository.saveSchedules(const []);
        return verified;
      }
      return _decodeRows(rows);
    }
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
    if (backend != null) {
      await _replaceRows(schedules);
      return;
    }
    await store.writeList(
      storageKey,
      schedules.map((schedule) => schedule.toJson()).toList(),
    );
  }

  SecureEntityCodec get _codec => SecureEntityCodec(store.cipher);

  Future<List<ShiftSchedule>> _loadLegacyOrPlain() async {
    if (await store.contains(storageKey)) {
      final decoded = await store.readList(storageKey);
      return decoded.map((entry) {
        return ShiftSchedule.fromJson(Map<String, Object?>.from(entry as Map));
      }).toList();
    }
    return plainRepository.loadSchedules();
  }

  Future<List<ShiftSchedule>> _decodeRows(
    List<SecureEntityRecord> rows,
  ) async {
    final schedules = <ShiftSchedule>[];
    for (final row in rows) {
      schedules.add(ShiftSchedule.fromJson(await _codec.decode(row)));
    }
    return schedules;
  }

  Future<void> _replaceRows(List<ShiftSchedule> schedules) async {
    final records = <SecureEntityRecord>[];
    for (final schedule in schedules) {
      records.add(await _codec.encode(schedule.id, schedule.toJson()));
    }
    await backend!.replaceSecureEntities(entityKind, records);
  }
}
