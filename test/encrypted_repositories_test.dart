import 'package:flutter_test/flutter_test.dart';
import 'package:my_second_memory/src/features/memory_items/data/encrypted_memory_repository.dart';
import 'package:my_second_memory/src/features/memory_items/data/memory_repository.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_item.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_type.dart';
import 'package:my_second_memory/src/features/security/data/app_cipher.dart';
import 'package:my_second_memory/src/features/security/data/encrypted_json_store.dart';
import 'package:my_second_memory/src/features/shift_schedules/data/encrypted_shift_schedule_repository.dart';
import 'package:my_second_memory/src/features/shift_schedules/data/shift_schedule_repository.dart';
import 'package:my_second_memory/src/features/shift_schedules/domain/shift_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('encrypted memory repository migrates plaintext records', () async {
    SharedPreferences.setMockInitialValues({});
    final date = DateTime(2026, 7, 7);
    final plain = _MemoryRepository([
      MemoryItem(
        id: 'note',
        type: MemoryType.note,
        title: 'Запись',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
    ]);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 1),
    );
    final repository = EncryptedMemoryRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: plain,
    );

    final items = await repository.loadItems();

    expect(items.single.id, 'note');
    expect(plain.items, isEmpty);
    expect(await repository.loadItems(), hasLength(1));
  });

  test('encrypted shift repository migrates plaintext schedules', () async {
    SharedPreferences.setMockInitialValues({});
    final date = DateTime(2026, 7, 7);
    final plain = _ShiftRepository([
      ShiftSchedule(
        id: 'shift',
        organizationName: 'Завод',
        colorValue: 0xFF16A34A,
        startDate: date,
        workDays: 2,
        restDays: 2,
      ),
    ]);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 2),
    );
    final repository = EncryptedShiftScheduleRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: plain,
    );

    final schedules = await repository.loadSchedules();

    expect(schedules.single.organizationName, 'Завод');
    expect(plain.schedules, isEmpty);
    expect(await repository.loadSchedules(), hasLength(1));
  });
}

class _MemoryRepository implements MemoryRepository {
  _MemoryRepository(this.items);

  List<MemoryItem> items;

  @override
  Future<List<MemoryItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<MemoryItem> items) async {
    this.items = items;
  }
}

class _ShiftRepository implements ShiftScheduleRepository {
  _ShiftRepository(this.schedules);

  List<ShiftSchedule> schedules;

  @override
  Future<List<ShiftSchedule>> loadSchedules() async => schedules;

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {
    this.schedules = schedules;
  }
}
