import '../../memory_items/domain/memory_item.dart';
import '../../security/data/app_cipher.dart';
import '../data/sync_local_store.dart';
import '../data/sync_remote_store.dart';
import 'encrypted_entity_sync_engine.dart';
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
    final remoteEntities = await remote.fetchEntities();
    final outcome = await EncryptedEntitySyncEngine<MemoryItem>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.memoryItem,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
      toJson: (item) => item.toJson(),
      fromJson: MemoryItem.fromJson,
    ).merge(
      localItems: localItems,
      remoteEntities: remoteEntities,
      replaceLocal: replaceLocal,
    );
    await remote.applyEntities(outcome.changesToUpload);
    return outcome.result;
  }
}
