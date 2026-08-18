import 'package:ezhednevnik_v2/src/features/accounts/domain/account_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/domain/shift_schedule.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_local_store.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_remote_store.dart';
import 'package:ezhednevnik_v2/src/features/sync/domain/app_sync_engine.dart';
import 'package:ezhednevnik_v2/src/features/sync/domain/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('shift colors and accounts merge across two devices', () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
    final firstCipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index),
    );
    final secondCipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index),
    );
    final firstUpdated = DateTime(2026, 8, 18, 10);
    final secondUpdated = DateTime(2026, 8, 18, 11);
    var firstShifts = [
      ShiftSchedule(
        id: 'windows-shift',
        organizationName: 'Windows work',
        colorValue: 0xFFE53935,
        startDate: DateTime(2026, 8, 1),
        workDays: 2,
        restDays: 2,
        updatedAt: firstUpdated,
      ),
    ];
    var firstAccounts = [
      AccountItem(
        id: 'windows-account',
        serviceName: 'Windows mail',
        login: 'first',
        password: 'first-secret',
        createdAt: firstUpdated,
        updatedAt: firstUpdated,
      ),
    ];

    await _sync(
      remote: remote,
      cipher: firstCipher,
      shifts: firstShifts,
      replaceShifts: (value) async => firstShifts = value,
      accounts: firstAccounts,
      replaceAccounts: (value) async => firstAccounts = value,
    );

    var secondShifts = [
      ShiftSchedule(
        id: 'android-shift',
        organizationName: 'Android work',
        colorValue: 0xFF1E88E5,
        startDate: DateTime(2026, 8, 2),
        workDays: 1,
        restDays: 3,
        updatedAt: secondUpdated,
      ),
    ];
    var secondAccounts = [
      AccountItem(
        id: 'android-account',
        serviceName: 'Android mail',
        login: 'second',
        password: 'second-secret',
        createdAt: secondUpdated,
        updatedAt: secondUpdated,
      ),
    ];
    final androidResult = await _sync(
      remote: remote,
      cipher: secondCipher,
      shifts: secondShifts,
      replaceShifts: (value) async => secondShifts = value,
      accounts: secondAccounts,
      replaceAccounts: (value) async => secondAccounts = value,
    );

    expect(androidResult.downloaded, 2);
    expect(androidResult.uploaded, 2);
    expect(secondShifts, hasLength(2));
    expect(
      secondShifts.singleWhere((item) => item.id == 'windows-shift').colorValue,
      0xFFE53935,
    );
    expect(secondAccounts, hasLength(2));
    expect(
      secondAccounts
          .singleWhere((item) => item.id == 'windows-account')
          .password,
      'first-secret',
    );

    await _sync(
      remote: remote,
      cipher: firstCipher,
      shifts: firstShifts,
      replaceShifts: (value) async => firstShifts = value,
      accounts: firstAccounts,
      replaceAccounts: (value) async => firstAccounts = value,
    );
    expect(firstShifts, hasLength(2));
    expect(firstAccounts, hasLength(2));
    expect(
      firstShifts.singleWhere((item) => item.id == 'android-shift').colorValue,
      0xFF1E88E5,
    );
    expect(
      firstAccounts
          .singleWhere((item) => item.id == 'android-account')
          .password,
      'second-secret',
    );
  });
}

Future<SyncRunResult> _sync({
  required _SyncRemote remote,
  required AppCipher cipher,
  required List<ShiftSchedule> shifts,
  required Future<void> Function(List<ShiftSchedule>) replaceShifts,
  required List<AccountItem> accounts,
  required Future<void> Function(List<AccountItem>) replaceAccounts,
}) {
  return AppSyncEngine(
    remote: remote,
    cipher: cipher,
    tombstones: const SyncTombstoneStore(),
  ).synchronize(
    memoryItems: const <MemoryItem>[],
    replaceMemoryItems: (_) async {},
    shiftSchedules: shifts,
    replaceShiftSchedules: replaceShifts,
    accounts: accounts,
    replaceAccounts: replaceAccounts,
  );
}

class _SyncRemote implements SyncRemoteStore {
  final _entities = <String, SyncRemoteEntity>{};

  @override
  String? get currentUserEmail => 'test@example.com';

  @override
  String? get currentUserId => 'user';

  @override
  Future<void> applyEntities(List<SyncRemoteEntity> entities) async {
    for (final entity in entities) {
      _entities['${entity.kind.storageName}:${entity.entityId}'] = entity;
    }
  }

  @override
  Future<void> createVaultProfile(SyncVaultProfile profile) async {}

  @override
  Future<List<SyncRemoteEntity>> fetchEntities() async =>
      _entities.values.toList();

  @override
  Future<SyncVaultProfile?> fetchVaultProfile() async => null;

  @override
  Future<void> resendSignupConfirmation(String email) async {}

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async {}

  @override
  Future<SyncAuthResult> signUp(String email, String password) async =>
      const SyncAuthResult(hasSession: true);

  @override
  Stream<void> watchAuthenticatedSession() => const Stream.empty();

  @override
  Stream<void> watchChanges() => const Stream.empty();
}
