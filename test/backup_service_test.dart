import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

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
        isUndated: true,
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
      recurrenceRepository: _RecurrenceRepository([
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
          isUndated: true,
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

  test('restore replaces and verifies all repositories', () async {
    final date = DateTime(2026, 8, 8);
    final memory = _MemoryRepository([
      _memoryItem('old-note', date),
    ]);
    final shifts = _ShiftRepository([
      _shiftSchedule('old-shift', date),
    ]);
    final accounts = _AccountRepository([
      _account('old-account', date),
    ]);
    final service = BackupService(
      memoryRepository: memory,
      shiftScheduleRepository: shifts,
      accountRepository: accounts,
    );

    await service.restore(BackupRestoreData(
      memoryItems: [_memoryItem('restored-note', date)],
      shiftSchedules: [_shiftSchedule('restored-shift', date)],
      accounts: [_account('restored-account', date)],
    ));

    expect((await memory.loadAll()).single.id, 'restored-note');
    expect((await shifts.loadSchedules()).single.id, 'restored-shift');
    expect((await accounts.loadAccounts()).single.id, 'restored-account');
  });

  test('restore rolls earlier repositories back when a write fails', () async {
    final date = DateTime(2026, 8, 8);
    final memory = _MemoryRepository([
      _memoryItem('old-note', date),
    ]);
    final shifts = _ShiftRepository([
      _shiftSchedule('old-shift', date),
    ]);
    final accounts = _FailOnceAccountRepository([
      _account('old-account', date),
    ]);
    final service = BackupService(
      memoryRepository: memory,
      shiftScheduleRepository: shifts,
      accountRepository: accounts,
    );

    await expectLater(
      service.restore(BackupRestoreData(
        memoryItems: [_memoryItem('restored-note', date)],
        shiftSchedules: [_shiftSchedule('restored-shift', date)],
        accounts: [_account('restored-account', date)],
      )),
      throwsStateError,
    );

    expect((await memory.loadAll()).single.id, 'old-note');
    expect((await shifts.loadSchedules()).single.id, 'old-shift');
    expect((await accounts.loadAccounts()).single.id, 'old-account');
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

MemoryItem _memoryItem(String id, DateTime date) {
  return MemoryItem(
    id: id,
    type: MemoryType.note,
    title: id,
    memoryDate: date,
    createdAt: date,
    updatedAt: date,
  );
}

ShiftSchedule _shiftSchedule(String id, DateTime date) {
  return ShiftSchedule(
    id: id,
    organizationName: id,
    colorValue: 0xFF2563EB,
    startDate: date,
    workDays: 2,
    restDays: 2,
    vacations: [
      ShiftVacation(
        id: '$id-vacation',
        startDate: date.add(const Duration(days: 5)),
        durationDays: 14,
      ),
    ],
  );
}

AccountItem _account(String id, DateTime date) {
  return AccountItem(
    id: id,
    serviceName: id,
    login: id,
    password: 'secret',
    createdAt: date,
    updatedAt: date,
  );
}

class _MemoryRepository implements MemoryRepository {
  _MemoryRepository(this.items);

  List<MemoryItem> items;

  @override
  Future<List<MemoryItem>> loadAll() async => List.of(items);

  @override
  Future<void> upsert(MemoryItem item) async {}

  @override
  Future<void> upsertAll(List<MemoryItem> items) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    this.items = List.of(items);
  }

  @override
  Future<void> close() async {}
}

class _ShiftRepository implements ShiftScheduleRepository {
  _ShiftRepository(this.schedules);

  List<ShiftSchedule> schedules;

  @override
  Future<List<ShiftSchedule>> loadSchedules() async => List.of(schedules);

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {
    this.schedules = List.of(schedules);
  }
}

class _AccountRepository implements AccountRepository {
  _AccountRepository(this.accounts);

  List<AccountItem> accounts;

  @override
  Future<List<AccountItem>> loadAccounts() async => List.of(accounts);

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {
    this.accounts = List.of(accounts);
  }
}

class _FailOnceAccountRepository extends _AccountRepository {
  _FailOnceAccountRepository(super.accounts);

  bool _shouldFail = true;

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('Simulated account write failure');
    }
    await super.saveAccounts(accounts);
  }
}

class _RecurrenceRepository implements RecurrenceRepository {
  _RecurrenceRepository(this.series);

  List<RecurrenceSeries> series;

  @override
  Future<List<RecurrenceSeries>> loadAll() async => List.of(series);

  @override
  Future<void> upsert(RecurrenceSeries series) async {}

  @override
  Future<void> upsertAll(List<RecurrenceSeries> series) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> replaceAll(List<RecurrenceSeries> series) async {
    this.series = List.of(series);
  }

  @override
  Future<void> close() async {}
}
