import 'package:flutter_test/flutter_test.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

import '../support/backup_test_support.dart';

void main() {
  test('backup JSON carries saved calculations and notes', () async {
    final date = DateTime(2026, 8, 8);
    final tools = FakeToolDataRepository(ToolDataSnapshot(
      calculations: [
        SavedToolCalculation(
          id: 'conversion-1',
          name: 'Расход',
          payload: const SavedConversionPayload(
            category: 'flow',
            fromUnit: 'm3_h',
            toUnit: 'l_s',
            value: 3.6,
          ),
          createdAt: date,
          updatedAt: date,
        ),
      ],
    ));
    final service = BackupService(
      memoryRepository: FakeMemoryRepository(const []),
      shiftScheduleRepository: FakeShiftRepository(const []),
      accountRepository: FakeAccountRepository(const []),
      toolDataRepository: tools,
    );

    final parsed =
        await service.parseBackupJson(await service.createBackupJson());

    expect(parsed.toolData.calculations.single.name, 'Расход');
  });

  test('restore replaces and verifies all repositories', () async {
    final date = DateTime(2026, 8, 8);
    final memory = FakeMemoryRepository([
      memoryItem('old-note', date),
    ]);
    final shifts = FakeShiftRepository([
      shiftSchedule('old-shift', date),
    ]);
    final accounts = FakeAccountRepository([
      account('old-account', date),
    ]);
    final finance = FakeFinanceRepository([financeEntry('old-finance', date)]);
    final tools = FakeToolDataRepository(const ToolDataSnapshot());
    final service = BackupService(
      memoryRepository: memory,
      shiftScheduleRepository: shifts,
      accountRepository: accounts,
      financeRepository: finance,
      toolDataRepository: tools,
    );

    await service.restore(BackupRestoreData(
      memoryItems: [memoryItem('restored-note', date)],
      shiftSchedules: [shiftSchedule('restored-shift', date)],
      accounts: [account('restored-account', date)],
      financeEntries: [financeEntry('restored-finance', date)],
      toolData: ToolDataSnapshot(calculations: [
        SavedToolCalculation(
          id: 'restored-conversion',
          name: 'Из копии',
          payload: const SavedConversionPayload(
            category: 'flow',
            fromUnit: 'm3_h',
            toUnit: 'l_s',
            value: 1,
          ),
          createdAt: date,
          updatedAt: date,
        ),
      ]),
    ));

    expect((await memory.loadAll()).single.id, 'restored-note');
    expect((await shifts.loadSchedules()).single.id, 'restored-shift');
    expect((await accounts.loadAccounts()).single.id, 'restored-account');
    expect((await finance.loadAll()).single.id, 'restored-finance');
    expect((await tools.load()).calculations.single.name, 'Из копии');
  });

  test('restore rolls every repository back when finance write fails',
      () async {
    final date = DateTime(2026, 8, 8);
    final memory = FakeMemoryRepository([memoryItem('old-note', date)]);
    final shifts = FakeShiftRepository([shiftSchedule('old-shift', date)]);
    final accounts = FakeAccountRepository([account('old-account', date)]);
    final finance = FailOnceFinanceRepository([
      financeEntry('old-finance', date),
    ]);
    final service = BackupService(
      memoryRepository: memory,
      shiftScheduleRepository: shifts,
      accountRepository: accounts,
      financeRepository: finance,
    );

    await expectLater(
      service.restore(BackupRestoreData(
        memoryItems: [memoryItem('new-note', date)],
        shiftSchedules: [shiftSchedule('new-shift', date)],
        accounts: [account('new-account', date)],
        financeEntries: [financeEntry('new-finance', date)],
      )),
      throwsStateError,
    );

    expect((await memory.loadAll()).single.id, 'old-note');
    expect((await shifts.loadSchedules()).single.id, 'old-shift');
    expect((await accounts.loadAccounts()).single.id, 'old-account');
    expect((await finance.loadAll()).single.id, 'old-finance');
  });

  test('restore rolls earlier repositories back when a write fails', () async {
    final date = DateTime(2026, 8, 8);
    final memory = FakeMemoryRepository([
      memoryItem('old-note', date),
    ]);
    final shifts = FakeShiftRepository([
      shiftSchedule('old-shift', date),
    ]);
    final accounts = FailOnceAccountRepository([
      account('old-account', date),
    ]);
    final service = BackupService(
      memoryRepository: memory,
      shiftScheduleRepository: shifts,
      accountRepository: accounts,
    );

    await expectLater(
      service.restore(BackupRestoreData(
        memoryItems: [memoryItem('restored-note', date)],
        shiftSchedules: [shiftSchedule('restored-shift', date)],
        accounts: [account('restored-account', date)],
      )),
      throwsStateError,
    );

    expect((await memory.loadAll()).single.id, 'old-note');
    expect((await shifts.loadSchedules()).single.id, 'old-shift');
    expect((await accounts.loadAccounts()).single.id, 'old-account');
  });
}
