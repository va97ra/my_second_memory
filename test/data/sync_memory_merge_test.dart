import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sync_test_support.dart';

void main() {
  test('pre-existing memory records merge into one union', () async {
    SharedPreferences.setMockInitialValues({});
    final remote = SyncRemote();
    final key = List<int>.generate(32, (index) => index + 1);
    final windowsCipher = AppCipher.fromKeyBytes(key);
    final androidCipher = AppCipher.fromKeyBytes(key);
    final createdAt = DateTime.utc(2026, 8, 18, 8);
    var windowsItems = [memoryItem('windows', 'Windows record', createdAt)];
    var androidItems = [
      memoryItem(
        'android',
        'Android record',
        createdAt.add(const Duration(minutes: 1)),
      ),
    ];
    addTearDown(windowsCipher.destroy);
    addTearDown(androidCipher.destroy);

    await sync(
      remote: remote,
      cipher: windowsCipher,
      memoryItems: windowsItems,
      replaceMemoryItems: (items) async => windowsItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    await sync(
      remote: remote,
      cipher: androidCipher,
      memoryItems: androidItems,
      replaceMemoryItems: (items) async => androidItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );
    await sync(
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
      remote.storedEntities.values
          .where((entity) => entity.kind == SyncEntityKind.memoryItem)
          .map((entity) => entity.entityId),
      unorderedEquals(['windows', 'android']),
    );
  });

  test('memory edits and deletion tombstones synchronize across devices',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = SyncRemote();
    final key = List<int>.generate(32, (index) => index + 1);
    final cipherA = AppCipher.fromKeyBytes(key);
    final cipherB = AppCipher.fromKeyBytes(key);
    final tombstonesA = MemoryTombstoneStore();
    final tombstonesB = MemoryTombstoneStore();
    final createdAt = DateTime.utc(2026, 8, 18, 8);
    var itemsA = [memoryItem('shared', 'Windows note', createdAt)];
    var itemsB = <MemoryItem>[];
    addTearDown(cipherA.destroy);
    addTearDown(cipherB.destroy);

    await sync(
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
    final encryptedMemory = remote.storedEntities.values.singleWhere(
      (entity) => entity.kind == SyncEntityKind.memoryItem,
    );
    expect(encryptedMemory.encryptedPayload, isNot(contains('Windows note')));

    final download = await sync(
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
    await sync(
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
    await sync(
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
    await sync(
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
    final deletion = await sync(
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
    final remote = SyncRemote();
    final cipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index + 1),
    );
    final tombstones = MemoryTombstoneStore();
    final updatedAt = DateTime.utc(2026, 8, 22, 12);
    final deletedAt = updatedAt.add(const Duration(minutes: 1));
    final stale = memoryItem('stale', 'Already deleted', updatedAt);
    var localItems = [stale];
    addTearDown(cipher.destroy);
    remote.storedEntities['memory_item:stale'] = SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: stale.id,
      encryptedPayload: await cipher.encryptString(jsonEncode(stale.toJson())),
      updatedAt: updatedAt,
    );
    await tombstones.markDeleted('user', stale.id, deletedAt);

    await sync(
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
    final remoteItem = remote.storedEntities['memory_item:stale']!;
    expect(remoteItem.isDeleted, isTrue);
    expect(remoteItem.deletedAt, deletedAt);
  });

  test('monthly and yearly records synchronize with complete templates',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = SyncRemote();
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

    await sync(
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
    await sync(
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
