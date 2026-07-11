import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/accounts/data/account_repository.dart';
import 'package:ezhednevnik_v2/src/features/accounts/domain/account_item.dart';
import 'package:ezhednevnik_v2/src/features/backup/data/backup_service.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_status.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/data/shift_schedule_repository.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/domain/shift_schedule.dart';

void main() {
  test('exports and parses memory records and shift schedules', () async {
    final date = DateTime(2026, 7, 3);
    final memoryRepository = _MemoryRepository([
      MemoryItem(
        id: 'note',
        type: MemoryType.note,
        title: 'Запись',
        body: 'Текст',
        timeMinutes: 12 * 60 + 45,
        remindAt: DateTime(2026, 7, 3, 12, 45),
        reminderSoundUri: 'content://media/alarm/4',
        reminderSoundName: 'Сигнал',
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
      accountRepository: _AccountRepository([
        AccountItem(
          id: 'account',
          serviceName: 'Mail',
          login: 'user',
          password: 'secret',
          createdAt: date,
          updatedAt: date,
        ),
      ]),
    );

    final raw = await service.createBackupJson();
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final restored = await service.parseBackupJson(raw);

    expect(decoded['format'], BackupService.format);
    expect(decoded['version'], BackupService.version);
    expect(restored.memoryItems, hasLength(1));
    expect(restored.memoryItems.single.id, 'note');
    expect(restored.memoryItems.single.timeMinutes, 12 * 60 + 45);
    expect(restored.memoryItems.single.reminderSoundUri,
        'content://media/alarm/4');
    expect(restored.memoryItems.single.reminderSoundName, 'Сигнал');
    expect(restored.memoryItems.single.status, MemoryStatus.done);
    expect(restored.memoryItems.single.imagePaths, ['/missing/photo.jpg']);
    expect(restored.shiftSchedules, hasLength(1));
    expect(restored.shiftSchedules.single.organizationName, 'Завод');
    expect(restored.accounts, hasLength(1));
    expect(restored.accounts.single.password, 'secret');
  });

  test('exports and restores encrypted zip with password', () async {
    final date = DateTime(2026, 7, 3);
    final service = BackupService(
      memoryRepository: _MemoryRepository([
        MemoryItem(
          id: 'note',
          type: MemoryType.note,
          title: 'Запись',
          body: 'Текст',
          timeMinutes: 8 * 60,
          memoryDate: date,
          createdAt: date,
          updatedAt: date,
        ),
      ]),
      shiftScheduleRepository: _ShiftRepository(const []),
      accountRepository: _AccountRepository([
        AccountItem(
          id: 'account',
          serviceName: 'Mail',
          login: 'user',
          password: 'secret',
          createdAt: date,
          updatedAt: date,
        ),
      ]),
    );

    final zip = await service.createEncryptedBackupZip('good-password');
    final restored = await service.parseBackupBytes(
      zip,
      password: 'good-password',
    );

    expect(restored.memoryItems.single.id, 'note');
    expect(restored.memoryItems.single.timeMinutes, 8 * 60);
    expect(restored.accounts.single.password, 'secret');
    expect(
      () => service.parseBackupBytes(zip, password: 'bad-password'),
      throwsFormatException,
    );
  });

  test('streaming backup file restores and rejects a wrong password', () async {
    final date = DateTime(2026, 7, 3);
    final service = BackupService(
      memoryRepository: _MemoryRepository([
        MemoryItem(
          id: 'streamed',
          type: MemoryType.note,
          title: 'Streamed',
          memoryDate: date,
          createdAt: date,
          updatedAt: date,
        ),
      ]),
      shiftScheduleRepository: _ShiftRepository(const []),
      accountRepository: _AccountRepository(const []),
    );

    final temp = await Directory.systemTemp.createTemp('backup_stream_test_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });
    final path = await service.createStreamingBackupFile(
      'good-password',
      temporaryRoot: temp.path,
    );
    expect(path, isNotNull);
    final bytes = await File(path!).readAsBytes();
    final restored = await service.parseBackupBytes(
      bytes,
      password: 'good-password',
    );

    expect(restored.memoryItems.single.id, 'streamed');
    expect(
      () => service.parseBackupBytes(bytes, password: 'bad-password'),
      throwsFormatException,
    );
    await service.deleteTemporaryBackup(path);
  });

  test('rejects unsupported backup files', () async {
    final service = BackupService(
      memoryRepository: _MemoryRepository(const []),
      shiftScheduleRepository: _ShiftRepository(const []),
      accountRepository: _AccountRepository(const []),
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
  Future<List<MemoryItem>> loadAll() async => items;

  @override
  Future<void> upsert(MemoryItem item) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {}

  @override
  Future<void> close() async {}
}

class _ShiftRepository implements ShiftScheduleRepository {
  _ShiftRepository(this.schedules);

  final List<ShiftSchedule> schedules;

  @override
  Future<List<ShiftSchedule>> loadSchedules() async => schedules;

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {}
}

class _AccountRepository implements AccountRepository {
  _AccountRepository(this.accounts);

  final List<AccountItem> accounts;

  @override
  Future<List<AccountItem>> loadAccounts() async => accounts;

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {}
}
