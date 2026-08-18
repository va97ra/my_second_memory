import '../../accounts/domain/account_item.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../security/data/app_cipher.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import '../../shift_schedules/domain/shift_schedule_deduplication.dart';
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
    final shiftsEngine = EncryptedEntitySyncEngine<ShiftSchedule>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.shiftSchedule,
      idOf: (schedule) => schedule.id,
      updatedAtOf: (schedule) => schedule.syncUpdatedAt,
      toJson: (schedule) => schedule.toJson(),
      fromJson: ShiftSchedule.fromJson,
    );
    var mergedShiftSchedules = shiftSchedules;
    Future<void> replaceMergedShiftSchedules(
      List<ShiftSchedule> schedules,
    ) async {
      mergedShiftSchedules = schedules;
      await replaceShiftSchedules(schedules);
    }

    var shiftsOutcome = await shiftsEngine.merge(
      localItems: shiftSchedules,
      remoteEntities: remoteEntities,
      replaceLocal: replaceMergedShiftSchedules,
    );
    final shiftDeduplication = deduplicateShiftSchedules(mergedShiftSchedules);
    if (shiftDeduplication.duplicateIds.isNotEmpty) {
      final userId = remote.currentUserId!;
      var deletedAt = DateTime.now();
      for (final schedule in mergedShiftSchedules) {
        if (!deletedAt.isAfter(schedule.syncUpdatedAt)) {
          deletedAt = schedule.syncUpdatedAt.add(
            const Duration(microseconds: 1),
          );
        }
      }
      for (final duplicateId in shiftDeduplication.duplicateIds) {
        await tombstones.markDeleted(
          userId,
          duplicateId,
          deletedAt,
          kind: SyncEntityKind.shiftSchedule,
        );
      }

      mergedShiftSchedules = shiftDeduplication.schedules;
      await replaceShiftSchedules(mergedShiftSchedules);
      final cleanupOutcome = await shiftsEngine.merge(
        localItems: mergedShiftSchedules,
        remoteEntities: remoteEntities,
        replaceLocal: replaceMergedShiftSchedules,
      );
      shiftsOutcome = EntitySyncOutcome(
        result: SyncRunResult(
          downloaded: shiftsOutcome.result.downloaded,
          uploaded: cleanupOutcome.result.uploaded,
          deleted: shiftsOutcome.result.deleted +
              shiftDeduplication.duplicateIds.length,
        ),
        changesToUpload: cleanupOutcome.changesToUpload,
      );
    }
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
