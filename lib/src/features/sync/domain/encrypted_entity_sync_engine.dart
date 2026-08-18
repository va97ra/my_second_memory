import 'dart:convert';

import '../../security/data/app_cipher.dart';
import '../data/sync_local_store.dart';
import '../data/sync_remote_store.dart';
import 'sync_models.dart';

class EntitySyncOutcome {
  const EntitySyncOutcome({
    required this.result,
    required this.changesToUpload,
  });

  final SyncRunResult result;
  final List<SyncRemoteEntity> changesToUpload;
}

class EncryptedEntitySyncEngine<T> {
  const EncryptedEntitySyncEngine({
    required this.remote,
    required this.cipher,
    required this.tombstones,
    required this.kind,
    required this.idOf,
    required this.updatedAtOf,
    required this.toJson,
    required this.fromJson,
  });

  final SyncRemoteStore remote;
  final AppCipher cipher;
  final SyncTombstoneStore tombstones;
  final SyncEntityKind kind;
  final String Function(T item) idOf;
  final DateTime Function(T item) updatedAtOf;
  final Map<String, Object?> Function(T item) toJson;
  final T Function(Map<String, Object?> json) fromJson;

  Future<EntitySyncOutcome> merge({
    required List<T> localItems,
    required List<SyncRemoteEntity> remoteEntities,
    required Future<void> Function(List<T> items) replaceLocal,
  }) async {
    final userId = remote.currentUserId;
    if (userId == null) {
      throw StateError('Synchronization account is signed out');
    }

    final remoteById = {
      for (final entity in remoteEntities)
        if (entity.kind == kind) entity.entityId: entity,
    };
    final localById = {for (final item in localItems) idOf(item): item};
    final deletedById = await tombstones.read(userId, kind: kind);
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
        if (local != null && updatedAtOf(local).isAfter(remoteDeletion)) {
          changesToUpload.add(await _encode(local));
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

      final remoteItem = await _decode(remoteEntity);
      if (local == null ||
          updatedAtOf(remoteItem).isAfter(updatedAtOf(local))) {
        localById[id] = remoteItem;
        downloaded++;
        if (localDeletion != null) {
          deletedById.remove(id);
          tombstonesChanged = true;
        }
      } else if (updatedAtOf(local).isAfter(updatedAtOf(remoteItem))) {
        changesToUpload.add(await _encode(local));
      }
    }

    for (final item in localById.values) {
      final id = idOf(item);
      final deletion = deletedById[id];
      if (deletion != null && updatedAtOf(item).isAfter(deletion)) {
        deletedById.remove(id);
        tombstonesChanged = true;
      }
      if (!remoteById.containsKey(id)) {
        changesToUpload.add(await _encode(item));
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
    if (tombstonesChanged) {
      await tombstones.write(userId, deletedById, kind: kind);
    }

    return EntitySyncOutcome(
      result: SyncRunResult(
        downloaded: downloaded,
        uploaded: changesToUpload.length,
        deleted: deleted,
      ),
      changesToUpload: changesToUpload,
    );
  }

  Future<SyncRemoteEntity> _encode(T item) async {
    return SyncRemoteEntity(
      kind: kind,
      entityId: idOf(item),
      encryptedPayload: await cipher.encryptString(jsonEncode(toJson(item))),
      updatedAt: updatedAtOf(item),
    );
  }

  Future<T> _decode(SyncRemoteEntity entity) async {
    final payload = entity.encryptedPayload;
    if (payload == null) throw const FormatException('Missing sync payload');
    final json = Map<String, Object?>.from(
      jsonDecode(await cipher.decryptString(payload)) as Map,
    );
    final item = fromJson(json);
    if (idOf(item) != entity.entityId) {
      throw const FormatException('Synchronization entity id mismatch');
    }
    return item;
  }

  SyncRemoteEntity _deletion(String id, DateTime deletedAt) {
    return SyncRemoteEntity(
      kind: kind,
      entityId: id,
      updatedAt: deletedAt,
      deletedAt: deletedAt,
    );
  }
}
