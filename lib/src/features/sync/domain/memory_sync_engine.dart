import 'dart:convert';

import '../../memory_items/domain/memory_item.dart';
import '../../security/data/app_cipher.dart';
import '../data/sync_local_store.dart';
import '../data/sync_remote_store.dart';
import 'sync_models.dart';

class MemorySyncEngine {
  const MemorySyncEngine({
    required this.remote,
    required this.cipher,
    required this.tombstones,
  });

  final SyncRemoteStore remote;
  final AppCipher cipher;
  final SyncTombstoneStore tombstones;

  Future<SyncRunResult> synchronize({
    required List<MemoryItem> localItems,
    required Future<void> Function(List<MemoryItem>) replaceLocal,
  }) async {
    final userId = remote.currentUserId;
    if (userId == null) {
      throw StateError('Synchronization account is signed out');
    }

    final remoteEntities = await remote.fetchEntities();
    final remoteById = {
      for (final entity in remoteEntities)
        if (entity.kind == SyncEntityKind.memoryItem) entity.entityId: entity,
    };
    final localById = {for (final item in localItems) item.id: item};
    final deletedById = await tombstones.read(userId);
    final changesToUpload = <SyncRemoteEntity>[];
    var downloaded = 0;
    var deleted = 0;
    var tombstonesChanged = false;

    for (final entry in remoteById.entries) {
      final id = entry.key;
      final remoteEntity = entry.value;
      final local = localById[id];
      final localDeletion = deletedById[id];

      if (remoteEntity.isDeleted) {
        final remoteDeletion = remoteEntity.deletedAt!;
        if (local != null && local.updatedAt.isAfter(remoteDeletion)) {
          changesToUpload.add(await _encodeItem(local));
          if (localDeletion != null) {
            deletedById.remove(id);
            tombstonesChanged = true;
          }
        } else {
          if (local != null) {
            localById.remove(id);
            deleted++;
          }
          if (localDeletion == null || remoteDeletion.isAfter(localDeletion)) {
            deletedById[id] = remoteDeletion;
            tombstonesChanged = true;
          }
        }
        continue;
      }

      if (localDeletion != null &&
          !remoteEntity.updatedAt.isAfter(localDeletion)) {
        changesToUpload.add(_deletion(id, localDeletion));
        continue;
      }

      final remoteItem = await _decodeItem(remoteEntity);
      if (local == null || remoteItem.updatedAt.isAfter(local.updatedAt)) {
        localById[id] = remoteItem;
        downloaded++;
        if (localDeletion != null) {
          deletedById.remove(id);
          tombstonesChanged = true;
        }
      } else if (local.updatedAt.isAfter(remoteItem.updatedAt)) {
        changesToUpload.add(await _encodeItem(local));
      }
    }

    for (final item in localById.values) {
      final deletion = deletedById[item.id];
      if (deletion != null && item.updatedAt.isAfter(deletion)) {
        deletedById.remove(item.id);
        tombstonesChanged = true;
      }
      if (!remoteById.containsKey(item.id)) {
        changesToUpload.add(await _encodeItem(item));
      }
    }

    for (final entry in deletedById.entries) {
      if (!remoteById.containsKey(entry.key)) {
        changesToUpload.add(_deletion(entry.key, entry.value));
      }
    }

    if (downloaded > 0 || deleted > 0) {
      await replaceLocal(localById.values.toList(growable: false));
    }
    await remote.applyEntities(changesToUpload);
    if (tombstonesChanged) await tombstones.write(userId, deletedById);

    return SyncRunResult(
      downloaded: downloaded,
      uploaded: changesToUpload.length,
      deleted: deleted,
    );
  }

  Future<SyncRemoteEntity> _encodeItem(MemoryItem item) async {
    return SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: item.id,
      encryptedPayload: await cipher.encryptString(jsonEncode(item.toJson())),
      updatedAt: item.updatedAt,
    );
  }

  Future<MemoryItem> _decodeItem(SyncRemoteEntity entity) async {
    final payload = entity.encryptedPayload;
    if (payload == null) throw const FormatException('Missing sync payload');
    final json = Map<String, Object?>.from(
      jsonDecode(await cipher.decryptString(payload)) as Map,
    );
    final item = MemoryItem.fromJson(json);
    if (item.id != entity.entityId) {
      throw const FormatException('Synchronization entity id mismatch');
    }
    return item;
  }

  SyncRemoteEntity _deletion(String id, DateTime deletedAt) {
    return SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: id,
      updatedAt: deletedAt,
      deletedAt: deletedAt,
    );
  }
}
