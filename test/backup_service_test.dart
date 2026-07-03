import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_second_memory/src/features/backup/data/backup_service.dart';
import 'package:my_second_memory/src/features/memory_items/data/memory_repository.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_item.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_status.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_type.dart';
import 'package:my_second_memory/src/features/shift_schedules/data/shift_schedule_repository.dart';
import 'package:my_second_memory/src/features/shift_schedules/domain/shift_schedule.dart';

void main() {
  test('exports and parses memory records and shift schedules', () async {
    final date = DateTime(2026, 7, 3);
    final memoryRepository = _MemoryRepository([
      MemoryItem(
        id: 'note',
        type: MemoryType.note,
        title: 'Запись',
        body: 'Текст',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
        status: MemoryStatus.done,
        imagePaths: const ['/missing/photo.jpg'],
      ),
    ]);
    final shiftRepository = _ShiftRepository([
      ShiftSchedule(
        id: 'shift',
        organizationName: 'Завод',
        colorValue: 0xFF16A34A,
        startDate: date,
        workDays: 2,
        restDays: 2,
      ),
    ]);
    final service = BackupService(
      memoryRepository: memoryRepository,
      shiftScheduleRepository: shiftRepository,
    );

    final raw = await service.createBackupJson();
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final restored = await service.parseBackupJson(raw);

    expect(decoded['format'], BackupService.format);
    expect(decoded['version'], BackupService.version);
    expect(restored.memoryItems, hasLength(1));
    expect(restored.memoryItems.single.id, 'note');
    expect(restored.memoryItems.single.status, MemoryStatus.done);
    expect(restored.memoryItems.single.imagePaths, ['/missing/photo.jpg']);
    expect(restored.shiftSchedules, hasLength(1));
    expect(restored.shiftSchedules.single.organizationName, 'Завод');
  });

  test('rejects unsupported backup files', () async {
    final service = BackupService(
      memoryRepository: _MemoryRepository(const []),
      shiftScheduleRepository: _ShiftRepository(const []),
    );

    expect(
      () => service.parseBackupJson('{"format":"wrong","version":1}'),
      throwsFormatException,
    );
  });
}

class _MemoryRepository implements MemoryRepository {
  _MemoryRepository(this.items);

  final List<MemoryItem> items;

  @override
  Future<List<MemoryItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<MemoryItem> items) async {}
}

class _ShiftRepository implements ShiftScheduleRepository {
  _ShiftRepository(this.schedules);

  final List<ShiftSchedule> schedules;

  @override
  Future<List<ShiftSchedule>> loadSchedules() async => schedules;

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {}
}
