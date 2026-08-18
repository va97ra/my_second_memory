import '../../accounts/domain/account_item.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../security/data/app_cipher.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import '../data/sync_local_store.dart';
import '../data/sync_remote_store.dart';
import 'encrypted_entity_sync_engine.dart';
import 'sync_models.dart';

class AppSyncEngine {
  const AppSyncEngine({
    required this.remote,
    required this.cipher,
    required this.tombstones,
  });

  final SyncRemoteStore remote;
  final AppCipher cipher;
  final SyncTombstoneStore tombstones;

  Future<SyncRunResult> synchronize({
    required List<MemoryItem> memoryItems,
    required Future<void> Function(List<MemoryItem>) replaceMemoryItems,
    required List<ShiftSchedule> shiftSchedules,
    required Future<void> Function(List<ShiftSchedule>) replaceShiftSchedules,
    required List<AccountItem> accounts,
    required Future<void> Function(List<AccountItem>) replaceAccounts,
  }) async {
    final remoteEntities = await remote.fetchEntities();
    final memoryOutcome = await EncryptedEntitySyncEngine<MemoryItem>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.memoryItem,
      idOf: (item) => item.id,
      updatedAtOf: (item) => item.updatedAt,
      toJson: (item) => item.toJson(),
      fromJson: MemoryItem.fromJson,
    ).merge(
      localItems: memoryItems,
      remoteEntities: remoteEntities,
      replaceLocal: replaceMemoryItems,
    );
    final shiftsOutcome = await EncryptedEntitySyncEngine<ShiftSchedule>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.shiftSchedule,
      idOf: (schedule) => schedule.id,
      updatedAtOf: (schedule) => schedule.syncUpdatedAt,
      toJson: (schedule) => schedule.toJson(),
      fromJson: ShiftSchedule.fromJson,
    ).merge(
      localItems: shiftSchedules,
      remoteEntities: remoteEntities,
      replaceLocal: replaceShiftSchedules,
    );
    final accountsOutcome = await EncryptedEntitySyncEngine<AccountItem>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.account,
      idOf: (account) => account.id,
      updatedAtOf: (account) => account.updatedAt,
      toJson: (account) => account.toJson(),
      fromJson: AccountItem.fromJson,
    ).merge(
      localItems: accounts,
      remoteEntities: remoteEntities,
      replaceLocal: replaceAccounts,
    );

    await remote.applyEntities([
      ...memoryOutcome.changesToUpload,
      ...shiftsOutcome.changesToUpload,
      ...accountsOutcome.changesToUpload,
    ]);
    return _combine([
      memoryOutcome.result,
      shiftsOutcome.result,
      accountsOutcome.result,
    ]);
  }

  SyncRunResult _combine(List<SyncRunResult> results) {
    return SyncRunResult(
      downloaded: results.fold(0, (total, item) => total + item.downloaded),
      uploaded: results.fold(0, (total, item) => total + item.uploaded),
      deleted: results.fold(0, (total, item) => total + item.deleted),
    );
  }
}
