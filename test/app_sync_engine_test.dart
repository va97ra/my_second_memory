import 'package:ezhednevnik_v2/src/features/accounts/domain/account_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_occurrence_exception.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_projection_service.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_series.dart';
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

  test('same schedule created on two devices converges without duplicates',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
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

    await _sync(
      remote: remote,
      cipher: firstCipher,
      shifts: windowsShifts,
      replaceShifts: (value) async => windowsShifts = value,
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    await _sync(
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
    final shiftEntities = remote._entities.values
        .where((entity) => entity.kind == SyncEntityKind.shiftSchedule)
        .toList();
    expect(shiftEntities.where((entity) => !entity.isDeleted), hasLength(1));
    expect(shiftEntities.where((entity) => entity.isDeleted), hasLength(1));

    await _sync(
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

  test('monthly and yearly records synchronize with complete templates',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
    final firstCipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index),
    );
    final secondCipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index),
    );
    final createdAt = DateTime(2026, 8, 18, 12);
    final suno = MemoryItem(
      id: 'suno-payment',
      type: MemoryType.payment,
      title: 'Suno',
      body: 'Suno',
      memoryDate: DateTime(2026, 8, 20),
      createdAt: createdAt,
      updatedAt: createdAt,
      repeatRule: RecurrenceFrequency.monthly.name,
      seriesId: 'monthly-suno',
      amountMinor: 99900,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final birthday = MemoryItem(
      id: 'annual-birthday',
      type: MemoryType.birthday,
      title: 'День рождения Анны',
      body: 'День рождения Анны',
      memoryDate: DateTime(2026, 9, 3),
      createdAt: createdAt,
      updatedAt: createdAt,
      repeatRule: RecurrenceFrequency.yearly.name,
      seriesId: 'yearly-anna',
      birthYear: 1992,
    );
    var firstSeries = [
      RecurrenceSeries(
        id: 'monthly-suno',
        frequency: RecurrenceFrequency.monthly,
        template: suno,
        startDate: suno.memoryDate,
        originItemId: suno.id,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      RecurrenceSeries(
        id: 'yearly-anna',
        frequency: RecurrenceFrequency.yearly,
        template: birthday,
        startDate: birthday.memoryDate,
        originItemId: birthday.id,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    ];
    var firstExceptions = [
      RecurrenceOccurrenceException(
        id: 'monthly-suno:20261020',
        seriesId: 'monthly-suno',
        occurrenceDate: DateTime(2026, 10, 20),
        kind: RecurrenceOccurrenceExceptionKind.skipped,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    ];

    await _sync(
      remote: remote,
      cipher: firstCipher,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
      recurrenceSeries: firstSeries,
      replaceRecurrenceSeries: (value) async => firstSeries = value,
      recurrenceExceptions: firstExceptions,
      replaceRecurrenceExceptions: (value) async => firstExceptions = value,
    );

    var secondSeries = <RecurrenceSeries>[];
    var secondExceptions = <RecurrenceOccurrenceException>[];
    await _sync(
      remote: remote,
      cipher: secondCipher,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
      recurrenceSeries: secondSeries,
      replaceRecurrenceSeries: (value) async => secondSeries = value,
      recurrenceExceptions: secondExceptions,
      replaceRecurrenceExceptions: (value) async => secondExceptions = value,
    );

    expect(secondSeries, hasLength(2));
    expect(secondExceptions, hasLength(1));
    final downloadedSuno =
        secondSeries.singleWhere((item) => item.id == 'monthly-suno');
    final september = const RecurrenceProjectionService()
        .itemsForRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
          series: [downloadedSuno],
          exceptions: secondExceptions,
          persistedItems: const [],
        )
        .single;
    expect(september.title, 'Suno');
    expect(september.body, 'Suno');
    expect(september.amountMinor, 99900);
    final downloadedBirthday =
        secondSeries.singleWhere((item) => item.id == 'yearly-anna');
    final nextYear = const RecurrenceProjectionService()
        .itemsForRange(
          start: DateTime(2027),
          end: DateTime(2027, 12, 31),
          series: [downloadedBirthday],
          exceptions: secondExceptions,
          persistedItems: const [],
        )
        .single;
    expect(nextYear.title, 'День рождения Анны');
    expect(nextYear.birthYear, 1992);
  });
}

Future<SyncRunResult> _sync({
  required _SyncRemote remote,
  required AppCipher cipher,
  required List<ShiftSchedule> shifts,
  required Future<void> Function(List<ShiftSchedule>) replaceShifts,
  required List<AccountItem> accounts,
  required Future<void> Function(List<AccountItem>) replaceAccounts,
  List<RecurrenceSeries> recurrenceSeries = const [],
  Future<void> Function(List<RecurrenceSeries>)? replaceRecurrenceSeries,
  List<RecurrenceOccurrenceException> recurrenceExceptions = const [],
  Future<void> Function(List<RecurrenceOccurrenceException>)?
      replaceRecurrenceExceptions,
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
    recurrenceSeries: recurrenceSeries,
    replaceRecurrenceSeries: replaceRecurrenceSeries ?? (_) async {},
    recurrenceExceptions: recurrenceExceptions,
    replaceRecurrenceExceptions: replaceRecurrenceExceptions ?? (_) async {},
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
