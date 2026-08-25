
import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sync_test_support.dart';

void main() {
  test('shift colors and accounts merge across two devices', () async {
    SharedPreferences.setMockInitialValues({});
    final remote = SyncRemote();
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

    await sync(
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
    final androidResult = await sync(
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

    await sync(
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

  test('same schedule created on two devices converges without duplicates',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = SyncRemote();
    final firstCipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index),
    );
    final secondCipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index),
    );
    var windowsShifts = [
      ShiftSchedule(
        id: 'windows-copy',
        organizationName: 'СВ Консалтинг',
        colorValue: 0xFF1976D2,
        startDate: DateTime(2026, 8, 2),
        workDays: 1,
        restDays: 3,
        vacations: [
          ShiftVacation(
            id: 'vacation',
            startDate: DateTime(2026, 8, 18),
            durationDays: 14,
          ),
        ],
        updatedAt: DateTime(2026, 8, 18, 10),
      ),
    ];
    var androidShifts = [
      ShiftSchedule(
        id: 'android-copy',
        organizationName: ' св  консалтинг ',
        colorValue: 0xFF1976D2,
        startDate: DateTime(2026, 8, 6),
        workDays: 1,
        restDays: 3,
        vacations: [
          ShiftVacation(
            id: 'vacation',
            startDate: DateTime(2026, 8, 18),
            durationDays: 14,
          ),
        ],
        updatedAt: DateTime(2026, 8, 18, 11),
      ),
    ];

    await sync(
      remote: remote,
      cipher: firstCipher,
      shifts: windowsShifts,
      replaceShifts: (value) async => windowsShifts = value,
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    await sync(
      remote: remote,
      cipher: secondCipher,
      shifts: androidShifts,
      replaceShifts: (value) async => androidShifts = value,
      accounts: const [],
      replaceAccounts: (_) async {},
    );

    expect(androidShifts, hasLength(1));
    expect(androidShifts.single.id, 'android-copy');
    expect(androidShifts.single.colorValue, 0xFF1976D2);
    expect(androidShifts.single.vacations, hasLength(1));
    final shiftEntities = remote.storedEntities.values
        .where((entity) => entity.kind == SyncEntityKind.shiftSchedule)
        .toList();
    expect(shiftEntities.where((entity) => !entity.isDeleted), hasLength(1));
    expect(shiftEntities.where((entity) => entity.isDeleted), hasLength(1));

    await sync(
      remote: remote,
      cipher: firstCipher,
      shifts: windowsShifts,
      replaceShifts: (value) async => windowsShifts = value,
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    expect(windowsShifts, hasLength(1));
    expect(windowsShifts.single.id, 'android-copy');
    expect(windowsShifts.single.vacations, hasLength(1));
  });
}
