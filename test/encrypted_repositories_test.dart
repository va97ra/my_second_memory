import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/data/database/app_database.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/encrypted_memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/sqlite_memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:ezhednevnik_v2/src/features/security/data/encrypted_json_store.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/data/encrypted_shift_schedule_repository.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/data/shift_schedule_repository.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/domain/shift_schedule.dart';
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

    final items = await repository.loadAll();

    expect(items.single.id, 'note');
    expect(plain.items, isEmpty);
    expect(await repository.loadAll(), hasLength(1));
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

  test('sqlite migration stores each memory item as an encrypted row',
      () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final plain = SqliteMemoryRepository(database: database);
    final date = DateTime(2026, 7, 7);
    await plain.replaceAll([
      MemoryItem(
        id: 'first',
        type: MemoryType.note,
        title: 'Первая',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
      MemoryItem(
        id: 'second',
        type: MemoryType.note,
        title: 'Вторая',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
    ]);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 3),
    );
    final repository = EncryptedMemoryRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: plain,
    );

    final migrated = await repository.loadAll();
    final rows = await plain.loadSecureEntities(
      EncryptedMemoryRepository.entityKind,
    );

    expect(migrated, hasLength(2));
    expect(await plain.loadAll(), isEmpty);
    expect(rows, hasLength(2));
    expect(rows.first.encryptedPayload, isNot(contains('Первая')));

    await repository.upsert(migrated.first.copyWith(body: 'Изменена'));
    expect(
        await plain.loadSecureEntities(
          EncryptedMemoryRepository.entityKind,
        ),
        hasLength(2));
    expect((await repository.loadAll()).first.body, 'Изменена');
  });
}

class _MemoryRepository implements MemoryRepository {
  _MemoryRepository(this.items);

  List<MemoryItem> items;

  @override
  Future<List<MemoryItem>> loadAll() async => items;

  @override
  Future<void> upsert(MemoryItem item) async {
    items = [
      for (final existing in items)
        if (existing.id == item.id) item else existing,
      if (!items.any((existing) => existing.id == item.id)) item,
    ];
  }

  @override
  Future<void> delete(String id) async {
    items = [
      for (final item in items)
        if (item.id != id) item
    ];
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    this.items = items;
  }

  @override
  Future<void> close() async {}
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
