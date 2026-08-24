import 'dart:convert';

import '../security/app_cipher.dart';
import 'sync_local_store.dart';
import 'sync_remote_store.dart';
import 'package:ez_domain/ez_domain.dart';

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
    this.withCanonicalUpdatedAt,
  });

  final SyncRemoteStore remote;
  final AppCipher cipher;
  final SyncTombstoneStore tombstones;
  final SyncEntityKind kind;
  final String Function(T item) idOf;
  final DateTime Function(T item) updatedAtOf;
  final Map<String, Object?> Function(T item) toJson;
  final T Function(Map<String, Object?> json) fromJson;
  final T Function(T item, DateTime updatedAt)? withCanonicalUpdatedAt;

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
    final initialDeletedById = {...deletedById};
    final changesToUpload = <SyncRemoteEntity>[];
    var downloaded = 0;
    var deleted = 0;
    var tombstonesChanged = false;
    var localChanged = false;

    // A previous interrupted sync can leave a stale local row beside its
    // tombstone. Resolve that state before considering cloud entities.
    for (final entry in [...deletedById.entries]) {
      final local = localById[entry.key];
      if (local == null) continue;
      if (updatedAtOf(local).isAfter(entry.value)) {
        deletedById.remove(entry.key);
        tombstonesChanged = true;
      } else {
        localById.remove(entry.key);
        localChanged = true;
        deleted++;
      }
    }

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
      if (local == null || remoteEntity.updatedAt.isAfter(updatedAtOf(local))) {
        localById[id] = remoteItem;
        downloaded++;
        if (localDeletion != null) {
          deletedById.remove(id);
          tombstonesChanged = true;
        }
      } else if (updatedAtOf(local).isAfter(remoteEntity.updatedAt)) {
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

    if (tombstonesChanged) {
      await tombstones.reconcile(
        userId,
        baseline: initialDeletedById,
        desired: deletedById,
        kind: kind,
      );
    }
    if (downloaded > 0 || deleted > 0 || localChanged) {
      await replaceLocal(localById.values.toList(growable: false));
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
    return withCanonicalUpdatedAt?.call(item, entity.updatedAt) ?? item;
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
