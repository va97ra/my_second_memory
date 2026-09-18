import 'dart:async';
import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/accounts/state/accounts_controller.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_providers.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_state.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/sync_test_support.dart';
import '../../support/widget_test_harness.dart';

void main() {
  for (final change in ['create', 'edit', 'delete']) {
    test('accounts and shifts preserve $change during cloud fetch', () async {
      SharedPreferences.setMockInitialValues({});
      final cipher = AppCipher.fromKeyBytes(List.generate(32, (i) => i));
      final remote = _BlockingRemote();
      final container = ProviderContainer(overrides: [
        localStorageScopeFactoryProvider
            .overrideWithValue(TestLocalStorageScope.new),
        shiftAlarmSchedulerProvider
            .overrideWithValue(const NoopShiftAlarmScheduler()),
        syncRemoteStoreProvider.overrideWithValue(remote),
        syncKeyStoreProvider.overrideWithValue(_KeyStore(cipher)),
        syncTombstoneStoreProvider.overrideWithValue(MemoryTombstoneStore()),
      ]);
      addTearDown(container.dispose);
      final accounts = container.read(accountsControllerProvider.notifier);
      final shifts = container.read(shiftSchedulesControllerProvider.notifier);
      await accounts.load();
      await shifts.load();
      final old = DateTime.utc(2020);
      AccountItem account(String id) => AccountItem(
          id: id,
          serviceName: id,
          login: '',
          password: 'old',
          createdAt: old,
          updatedAt: old);
      ShiftSchedule shift(String id) => ShiftSchedule(
          id: id,
          organizationName: id,
          colorValue: 0xFF1976D2,
          startDate: old,
          workDays: 1,
          restDays: 3,
          updatedAt: old);
      if (change != 'create') {
        await accounts.replaceAll([account('local')]);
        await shifts.replaceAll([shift('local')]);
      }
      // An incoming row forces the engine to commit its merged snapshot.
      for (final entry in [
        (SyncEntityKind.account, account('cloud').toJson()),
        (SyncEntityKind.shiftSchedule, shift('cloud').toJson()),
      ]) {
        remote.storedEntities[entry.$1.name] = SyncRemoteEntity(
          kind: entry.$1,
          entityId: 'cloud',
          updatedAt: old,
          encryptedPayload: await cipher.encryptString(jsonEncode(entry.$2)),
        );
      }
      final sync = container.read(syncControllerProvider.notifier);
      await sync.load();
      final run = sync.syncNow();
      await remote.started.future;
      switch (change) {
        case 'create':
          await accounts.add(account('local'));
          await shifts.add(shift('local'));
        case 'edit':
          await accounts.update(account('local').copyWith(password: 'new'));
          await shifts
              .update(shift('local').copyWith(organizationName: 'edited'));
        case 'delete':
          await accounts.delete('local');
          await shifts.delete('local');
      }
      remote.release.complete();
      await run;
      expect(container.read(syncControllerProvider).status, SyncStatus.ready);
      final savedAccounts = await const LocalAccountRepository().loadAccounts();
      final savedShifts =
          await const LocalShiftScheduleRepository().loadSchedules();
      expect(savedAccounts.map((a) => a.id), contains('cloud'));
      expect(savedShifts.map((s) => s.id), contains('cloud'));
      if (change == 'delete') {
        expect(savedAccounts.map((a) => a.id), isNot(contains('local')));
        expect(savedShifts.map((s) => s.id), isNot(contains('local')));
      } else {
        expect(savedAccounts.map((a) => a.id), contains('local'));
        expect(savedShifts.map((s) => s.id), contains('local'));
        if (change == 'edit') {
          expect(
              savedAccounts.firstWhere((a) => a.id == 'local').password, 'new');
          expect(
              savedShifts.firstWhere((s) => s.id == 'local').organizationName,
              'edited');
        }
      }
    });
  }
}

class _BlockingRemote extends SyncRemote {
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<List<SyncRemoteEntity>> fetchEntities() async {
    if (!started.isCompleted) started.complete();
    await release.future;
    return super.fetchEntities();
  }
}

class _KeyStore extends SyncKeyStore {
  _KeyStore(this.cipher);
  final AppCipher cipher;
  @override
  Future<AppCipher?> read(String userId) async => cipher;
}
