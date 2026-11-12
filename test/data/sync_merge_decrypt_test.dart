import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_test_support.dart';

/// О1: облачную сущность расшифровывают, только когда она нужна, — когда
/// местной нет или облачная новее. Иначе каждый прогон раз в две минуты
/// расшифровывал бы весь дневник.
void main() {
  final cipher = AppCipher.fromKeyBytes(List.filled(32, 5));
  final date = DateTime.utc(2026, 11, 12, 9);

  final local = [
    for (var index = 0; index < 50; index++)
      memoryItem('record-$index', 'Запись $index', date),
  ];

  Future<SyncRemoteEntity> uploaded(MemoryItem item) async => SyncRemoteEntity(
        kind: SyncEntityKind.memoryItem,
        entityId: item.id,
        encryptedPayload: await cipher.encryptString(jsonEncode(item.toJson())),
        updatedAt: item.updatedAt,
      );

  Future<({int decoded, List<MemoryItem> merged})> merge(
    List<MemoryItem> localItems,
    List<SyncRemoteEntity> remote,
  ) async {
    var decoded = 0;
    final outcome = await EncryptedEntitySyncEngine<MemoryItem>(
      remote: SyncRemote(),
      cipher: cipher,
      tombstones: MemoryTombstoneStore(),
      kind: SyncEntityKind.memoryItem,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
      toJson: (item) => item.toJson(),
      fromJson: (json) {
        decoded++;
        return MemoryItem.fromJson(json);
      },
    ).merge(
      localItems: localItems,
      remoteEntities: remote,
      replaceLocal: (_) async {},
    );
    return (decoded: decoded, merged: outcome.merged);
  }

  test('an unchanged diary is not decrypted at all', () async {
    final remote = [for (final item in local) await uploaded(item)];

    final result = await merge(local, remote);

    expect(result.decoded, 0);
    expect(result.merged, hasLength(50));
  });

  test('only the newer cloud record is decrypted, and it wins', () async {
    final edited = local[7].copyWith(
      body: 'Правка с другого устройства',
      updatedAt: date.add(const Duration(minutes: 1)),
    );
    final remote = [
      for (final item in local)
        await uploaded(item.id == edited.id ? edited : item),
    ];

    final result = await merge(local, remote);

    expect(result.decoded, 1);
    expect(
      result.merged.singleWhere((item) => item.id == edited.id).body,
      'Правка с другого устройства',
    );
  });

  test('a record missing here is decrypted and arrives', () async {
    final remote = [for (final item in local) await uploaded(item)];

    final result = await merge(local.sublist(1), remote);

    expect(result.decoded, 1);
    expect(result.merged, hasLength(50));
  });
}
