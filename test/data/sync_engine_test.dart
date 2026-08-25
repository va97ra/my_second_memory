import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('pre-existing memory records merge into one union', () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
    final key = List<int>.generate(32, (index) => index + 1);
    final windowsCipher = AppCipher.fromKeyBytes(key);
    final androidCipher = AppCipher.fromKeyBytes(key);
    final createdAt = DateTime.utc(2026, 8, 18, 8);
    var windowsItems = [_memoryItem('windows', 'Windows record', createdAt)];
    var androidItems = [
      _memoryItem(
        'android',
        'Android record',
        createdAt.add(const Duration(minutes: 1)),
      ),
    ];
    addTearDown(windowsCipher.destroy);
    addTearDown(androidCipher.destroy);

    await _sync(
      remote: remote,
      cipher: windowsCipher,
      memoryItems: windowsItems,
      replaceMemoryItems: (items) async => windowsItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    await _sync(
      remote: remote,
      cipher: androidCipher,
      memoryItems: androidItems,
      replaceMemoryItems: (items) async => androidItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    await _sync(
      remote: remote,
      cipher: windowsCipher,
      memoryItems: windowsItems,
      replaceMemoryItems: (items) async => windowsItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );

    expect(
      windowsItems.map((item) => item.id),
      unorderedEquals(['windows', 'android']),
    );
    expect(
      androidItems.map((item) => item.id),
      unorderedEquals(['windows', 'android']),
    );
    expect(
      remote._entities.values
          .where((entity) => entity.kind == SyncEntityKind.memoryItem)
          .map((entity) => entity.entityId),
      unorderedEquals(['windows', 'android']),
    );
  });

  test('memory edits and deletion tombstones synchronize across devices',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
    final key = List<int>.generate(32, (index) => index + 1);
    final cipherA = AppCipher.fromKeyBytes(key);
    final cipherB = AppCipher.fromKeyBytes(key);
    final tombstonesA = _MemoryTombstoneStore();
    final tombstonesB = _MemoryTombstoneStore();
    final createdAt = DateTime.utc(2026, 8, 18, 8);
    var itemsA = [_memoryItem('shared', 'Windows note', createdAt)];
    var itemsB = <MemoryItem>[];
    addTearDown(cipherA.destroy);
    addTearDown(cipherB.destroy);

    await _sync(
      remote: remote,
      cipher: cipherA,
      tombstones: tombstonesA,
      memoryItems: itemsA,
      replaceMemoryItems: (items) async => itemsA = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    final encryptedMemory = remote._entities.values.singleWhere(
      (entity) => entity.kind == SyncEntityKind.memoryItem,
    );
    expect(encryptedMemory.encryptedPayload, isNot(contains('Windows note')));

    final download = await _sync(
      remote: remote,
      cipher: cipherB,
      tombstones: tombstonesB,
      memoryItems: itemsB,
      replaceMemoryItems: (items) async => itemsB = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    expect(download.downloaded, 1);
    expect(itemsB.single.title, 'Windows note');

    itemsB = [
      itemsB.single.copyWith(
        title: 'Android edit',
        updatedAt: createdAt.add(const Duration(minutes: 1)),
      ),
    ];
    await _sync(
      remote: remote,
      cipher: cipherB,
      tombstones: tombstonesB,
      memoryItems: itemsB,
      replaceMemoryItems: (items) async => itemsB = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    await _sync(
      remote: remote,
      cipher: cipherA,
      tombstones: tombstonesA,
      memoryItems: itemsA,
      replaceMemoryItems: (items) async => itemsA = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    expect(itemsA.single.title, 'Android edit');

    final deletedAt = createdAt.add(const Duration(minutes: 2));
    itemsA = [];
    await tombstonesA.markDeleted('user', 'shared', deletedAt);
    await _sync(
      remote: remote,
      cipher: cipherA,
      tombstones: tombstonesA,
      memoryItems: itemsA,
      replaceMemoryItems: (items) async => itemsA = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    final deletion = await _sync(
      remote: remote,
      cipher: cipherB,
      tombstones: tombstonesB,
      memoryItems: itemsB,
      replaceMemoryItems: (items) async => itemsB = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    expect(deletion.deleted, 1);
    expect(itemsB, isEmpty);
  });

  test('newer tombstone removes an item from a stale local snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
    final cipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index + 1),
    );
    final tombstones = _MemoryTombstoneStore();
    final updatedAt = DateTime.utc(2026, 8, 22, 12);
    final deletedAt = updatedAt.add(const Duration(minutes: 1));
    final stale = _memoryItem('stale', 'Already deleted', updatedAt);
    var localItems = [stale];
    addTearDown(cipher.destroy);
    remote._entities['memory_item:stale'] = SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: stale.id,
      encryptedPayload: await cipher.encryptString(jsonEncode(stale.toJson())),
      updatedAt: updatedAt,
    );
    await tombstones.markDeleted('user', stale.id, deletedAt);

    await _sync(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      memoryItems: localItems,
      replaceMemoryItems: (items) async => localItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );

    expect(localItems, isEmpty);
    final remoteItem = remote._entities['memory_item:stale']!;
    expect(remoteItem.isDeleted, isTrue);
    expect(remoteItem.deletedAt, deletedAt);
  });

  test('remote envelope timestamp wins over a future legacy payload timestamp',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
    final cipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index + 1),
    );
    final remoteUpdatedAt = DateTime.utc(2026, 8, 22, 12);
    final localUpdatedAt = remoteUpdatedAt.add(const Duration(minutes: 1));
    final local = _memoryItem('clock-skew', 'Local edit', localUpdatedAt);
    final legacyPayload = _memoryItem(
      'clock-skew',
      'Old cloud edit',
      remoteUpdatedAt,
    ).toJson()
      ..['updatedAt'] = '2099-08-22T17:00:00.000';
    var localItems = [local];
    addTearDown(cipher.destroy);
    remote._entities['memory_item:clock-skew'] = SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: local.id,
      encryptedPayload: await cipher.encryptString(jsonEncode(legacyPayload)),
      updatedAt: remoteUpdatedAt,
    );

    await _sync(
      remote: remote,
      cipher: cipher,
      tombstones: _MemoryTombstoneStore(),
      memoryItems: localItems,
      replaceMemoryItems: (items) async => localItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );

    expect(localItems.single.title, 'Local edit');
    expect(
      remote._entities['memory_item:clock-skew']!.updatedAt,
      localUpdatedAt,
    );
  });

  test('downloaded legacy payload receives its envelope timestamp', () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
    final cipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index + 1),
    );
    final remoteUpdatedAt = DateTime.utc(2026, 8, 22, 12);
    final legacyPayload = _memoryItem(
      'legacy-download',
      'Cloud record',
      remoteUpdatedAt,
    ).toJson()
      ..['updatedAt'] = '2099-08-22T17:00:00.000';
    var localItems = <MemoryItem>[];
    addTearDown(cipher.destroy);
    remote._entities['memory_item:legacy-download'] = SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: 'legacy-download',
      encryptedPayload: await cipher.encryptString(jsonEncode(legacyPayload)),
      updatedAt: remoteUpdatedAt,
    );

    await _sync(
      remote: remote,
      cipher: cipher,
      tombstones: _MemoryTombstoneStore(),
      memoryItems: localItems,
      replaceMemoryItems: (items) async => localItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );

    expect(localItems.single.title, 'Cloud record');
    expect(localItems.single.updatedAt, remoteUpdatedAt);
  });

  test(
      'tombstone defeats an older remote envelope with a future legacy payload timestamp',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = _SyncRemote();
    final cipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index + 1),
    );
    final tombstones = _MemoryTombstoneStore();
    final remoteUpdatedAt = DateTime.utc(2026, 8, 22, 12);
    final deletedAt = remoteUpdatedAt.add(const Duration(minutes: 1));
    final legacyPayload = _memoryItem(
      'deleted-clock-skew',
      'Deleted cloud copy',
      remoteUpdatedAt,
    ).toJson()
      ..['updatedAt'] = '2099-08-22T17:00:00.000';
    var localItems = <MemoryItem>[];
    addTearDown(cipher.destroy);
    remote._entities['memory_item:deleted-clock-skew'] = SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: 'deleted-clock-skew',
      encryptedPayload: await cipher.encryptString(jsonEncode(legacyPayload)),
      updatedAt: remoteUpdatedAt,
    );
    await tombstones.markDeleted(
      'user',
      'deleted-clock-skew',
      deletedAt,
    );

    await _sync(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      memoryItems: localItems,
      replaceMemoryItems: (items) async => localItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );

    expect(localItems, isEmpty);
    final remoteItem = remote._entities['memory_item:deleted-clock-skew']!;
    expect(remoteItem.isDeleted, isTrue);
    expect(remoteItem.deletedAt, deletedAt);
    expect(
      await tombstones.read('user'),
      containsPair('deleted-clock-skew', deletedAt),
    );
  });

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
  SyncTombstoneStore tombstones = const SyncTombstoneStore(),
  List<MemoryItem> memoryItems = const [],
  Future<void> Function(List<MemoryItem>)? replaceMemoryItems,
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
    tombstones: tombstones,
  ).synchronize(
    memoryItems: memoryItems,
    replaceMemoryItems: replaceMemoryItems ?? (_) async {},
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

MemoryItem _memoryItem(String id, String title, DateTime date) => MemoryItem(
      id: id,
      type: MemoryType.note,
      title: title,
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );

class _MemoryTombstoneStore extends SyncTombstoneStore {
  final _values = <SyncEntityKind, Map<String, DateTime>>{};

  @override
  Future<Map<String, DateTime>> read(
    String userId, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async =>
      {...?_values[kind]};

  @override
  Future<void> write(
    String userId,
    Map<String, DateTime> next, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    _values[kind] = {...next};
  }

  @override
  Future<void> markDeleted(
    String userId,
    String id,
    DateTime deletedAt, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    (_values[kind] ??= {})[id] = deletedAt;
  }
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
