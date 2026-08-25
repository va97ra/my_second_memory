
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_data/ez_data.dart';

import '../support/backup_test_support.dart';

void main() {
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
    final service = BackupService(
      memoryRepository: memory,
      shiftScheduleRepository: shifts,
      accountRepository: accounts,
    );

    await service.restore(BackupRestoreData(
      memoryItems: [memoryItem('restored-note', date)],
      shiftSchedules: [shiftSchedule('restored-shift', date)],
      accounts: [account('restored-account', date)],
    ));

    expect((await memory.loadAll()).single.id, 'restored-note');
    expect((await shifts.loadSchedules()).single.id, 'restored-shift');
    expect((await accounts.loadAccounts()).single.id, 'restored-account');
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
