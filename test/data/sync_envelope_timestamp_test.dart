import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sync_test_support.dart';

void main() {
  test('remote envelope timestamp wins over a future legacy payload timestamp',
      () async {
    SharedPreferences.setMockInitialValues({});
    final remote = SyncRemote();
    final cipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index + 1),
    );
    final remoteUpdatedAt = DateTime.utc(2026, 8, 22, 12);
    final localUpdatedAt = remoteUpdatedAt.add(const Duration(minutes: 1));
    final local = memoryItem('clock-skew', 'Local edit', localUpdatedAt);
    final legacyPayload = memoryItem(
      'clock-skew',
      'Old cloud edit',
      remoteUpdatedAt,
    ).toJson()
      ..['updatedAt'] = '2099-08-22T17:00:00.000';
    var localItems = [local];
    addTearDown(cipher.destroy);
    remote.storedEntities['memory_item:clock-skew'] = SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: local.id,
      encryptedPayload: await cipher.encryptString(jsonEncode(legacyPayload)),
      updatedAt: remoteUpdatedAt,
    );

    await sync(
      remote: remote,
      cipher: cipher,
      tombstones: MemoryTombstoneStore(),
      memoryItems: localItems,
      replaceMemoryItems: (items) async => localItems = items,
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
    );

    expect(localItems.single.title, 'Local edit');
    expect(
      remote.storedEntities['memory_item:clock-skew']!.updatedAt,
      localUpdatedAt,
    );
  });

  test('downloaded legacy payload receives its envelope timestamp', () async {
    SharedPreferences.setMockInitialValues({});
    final remote = SyncRemote();
    final cipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index + 1),
    );
    final remoteUpdatedAt = DateTime.utc(2026, 8, 22, 12);
    final legacyPayload = memoryItem(
      'legacy-download',
      'Cloud record',
      remoteUpdatedAt,
    ).toJson()
      ..['updatedAt'] = '2099-08-22T17:00:00.000';
    var localItems = <MemoryItem>[];
    addTearDown(cipher.destroy);
    remote.storedEntities['memory_item:legacy-download'] = SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: 'legacy-download',
      encryptedPayload: await cipher.encryptString(jsonEncode(legacyPayload)),
      updatedAt: remoteUpdatedAt,
    );

    await sync(
      remote: remote,
      cipher: cipher,
      tombstones: MemoryTombstoneStore(),
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
    final remote = SyncRemote();
    final cipher = AppCipher.fromKeyBytes(
      List<int>.generate(32, (index) => index + 1),
    );
    final tombstones = MemoryTombstoneStore();
    final remoteUpdatedAt = DateTime.utc(2026, 8, 22, 12);
    final deletedAt = remoteUpdatedAt.add(const Duration(minutes: 1));
    final legacyPayload = memoryItem(
      'deleted-clock-skew',
      'Deleted cloud copy',
      remoteUpdatedAt,
    ).toJson()
      ..['updatedAt'] = '2099-08-22T17:00:00.000';
    var localItems = <MemoryItem>[];
    addTearDown(cipher.destroy);
    remote.storedEntities['memory_item:deleted-clock-skew'] = SyncRemoteEntity(
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
    final remoteItem = remote.storedEntities['memory_item:deleted-clock-skew']!;
    expect(remoteItem.isDeleted, isTrue);
    expect(remoteItem.deletedAt, deletedAt);
    expect(
      await tombstones.read('user'),
      containsPair('deleted-clock-skew', deletedAt),
    );
  });
}
