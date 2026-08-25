import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

import '../support/backup_test_support.dart';

void main() {
  test('exports and parses memory records and shift schedules', () async {
    final date = DateTime(2026, 7, 3);
    final memoryRepository = FakeMemoryRepository([
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
        isUndated: true,
      ),
    ]);
    final shiftRepository = FakeShiftRepository([
      ShiftSchedule(
        id: 'shift',
        organizationName: 'Завод',
        colorValue: 0xFF16A34A,
        startDate: date,
        workDays: 2,
        restDays: 2,
        vacations: [
          ShiftVacation(
            id: 'summer-vacation',
            startDate: DateTime(2026, 8, 18),
            durationDays: 14,
          ),
        ],
      ),
    ]);
    final recurringTemplate = MemoryItem(
      id: 'payment',
      type: MemoryType.payment,
      title: 'Интернет',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      amountMinor: 90000,
    );
    final service = BackupService(
      memoryRepository: memoryRepository,
      shiftScheduleRepository: shiftRepository,
      accountRepository: FakeAccountRepository([
        AccountItem(
          id: 'account',
          serviceName: 'Mail',
          login: 'user',
          password: 'secret',
          createdAt: date,
          updatedAt: date,
        ),
      ]),
      recurrenceRepository: FakeRecurrenceRepository([
        RecurrenceSeries(
          id: 'monthly-payment',
          frequency: RecurrenceFrequency.monthly,
          template: recurringTemplate,
          startDate: date,
          originItemId: recurringTemplate.id,
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
    expect(restored.memoryItems.single.isUndated, isTrue);
    expect(restored.shiftSchedules, hasLength(1));
    expect(restored.shiftSchedules.single.organizationName, 'Завод');
    expect(restored.shiftSchedules.single.vacations, hasLength(1));
    expect(restored.shiftSchedules.single.vacations.single.endDate,
        DateTime(2026, 8, 31));
    expect(restored.accounts, hasLength(1));
    expect(restored.accounts.single.password, 'secret');
    expect(restored.recurrenceSeries.single.id, 'monthly-payment');
    expect(restored.recurrenceSeries.single.template.amountMinor, 90000);
  });

  test('exports and restores encrypted zip with password', () async {
    final date = DateTime(2026, 7, 3);
    final service = BackupService(
      memoryRepository: FakeMemoryRepository([
        MemoryItem(
          id: 'note',
          type: MemoryType.note,
          title: 'Запись',
          body: 'Текст',
          timeMinutes: 8 * 60,
          memoryDate: date,
          createdAt: date,
          updatedAt: date,
          isUndated: true,
        ),
      ]),
      shiftScheduleRepository: FakeShiftRepository(const []),
      accountRepository: FakeAccountRepository([
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
    expect(restored.memoryItems.single.isUndated, isTrue);
    expect(restored.accounts.single.password, 'secret');
    expect(
      () => service.parseBackupBytes(zip, password: 'bad-password'),
      throwsA(isA<BackupPasswordException>()),
    );
  });

  test('streaming backup file restores and rejects a wrong password', () async {
    final date = DateTime(2026, 7, 3);
    final service = BackupService(
      memoryRepository: FakeMemoryRepository([
        MemoryItem(
          id: 'streamed',
          type: MemoryType.note,
          title: 'Streamed',
          memoryDate: date,
          createdAt: date,
          updatedAt: date,
        ),
      ]),
      shiftScheduleRepository: FakeShiftRepository(const []),
      accountRepository: FakeAccountRepository(const []),
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
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifest = jsonDecode(
      utf8.decode(archive.findFile('manifest.json')!.content as List<int>),
    ) as Map<String, Object?>;
    expect(manifest['version'], BackupService.streamingZipVersion);
    expect(manifest['cipher'], 'aes-256-gcm');
    expect(archive.findFile('payload.bin'), isNotNull);
    final restored = await service.parseBackupBytes(
      bytes,
      password: 'good-password',
    );

    expect(restored.memoryItems.single.id, 'streamed');
    expect(
      () => service.parseBackupBytes(bytes, password: 'bad-password'),
      throwsA(isA<BackupPasswordException>()),
    );
    await service.deleteTemporaryBackup(path);
  });

  test('rejects unsupported backup files', () async {
    final service = BackupService(
      memoryRepository: FakeMemoryRepository(const []),
      shiftScheduleRepository: FakeShiftRepository(const []),
      accountRepository: FakeAccountRepository(const []),
    );

    expect(
      () => service.parseBackupJson('{"format":"wrong","version":1}'),
      throwsFormatException,
    );
  });
}
