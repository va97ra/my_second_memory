import 'package:ez_domain/ez_domain.dart';
import '../security/app_cipher.dart';
import 'sync_local_store.dart';
import 'sync_remote_store.dart';
import 'encrypted_entity_sync_engine.dart';

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
    required List<RecurrenceSeries> recurrenceSeries,
    required Future<void> Function(List<RecurrenceSeries>)
        replaceRecurrenceSeries,
    required List<RecurrenceOccurrenceException> recurrenceExceptions,
    required Future<void> Function(List<RecurrenceOccurrenceException>)
        replaceRecurrenceExceptions,
    List<FinanceEntry> financeEntries = const [],
    Future<void> Function(List<FinanceEntry>)? replaceFinanceEntries,
    List<SavedToolCalculation> toolCalculations = const [],
    Future<void> Function(List<SavedToolCalculation>)? replaceToolCalculations,
    List<ReferenceBookmark> toolBookmarks = const [],
    Future<void> Function(List<ReferenceBookmark>)? replaceToolBookmarks,
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
      withCanonicalUpdatedAt: _canonicalMemoryItem,
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
      withCanonicalUpdatedAt: (schedule, updatedAt) =>
          schedule.copyWith(updatedAt: updatedAt),
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
      withCanonicalUpdatedAt: (account, updatedAt) {
        final delta = updatedAt.difference(account.updatedAt);
        return account.copyWith(
          createdAt: account.createdAt.add(delta),
          updatedAt: updatedAt,
        );
      },
    ).merge(
      localItems: accounts,
      remoteEntities: remoteEntities,
      replaceLocal: replaceAccounts,
    );
    final recurrenceExceptionsOutcome =
        await EncryptedEntitySyncEngine<RecurrenceOccurrenceException>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.recurrenceException,
      idOf: (exception) => exception.id,
      updatedAtOf: (exception) => exception.updatedAt,
      toJson: (exception) => exception.toJson(),
      fromJson: RecurrenceOccurrenceException.fromJson,
      withCanonicalUpdatedAt: (exception, updatedAt) {
        final delta = updatedAt.difference(exception.updatedAt);
        final item = exception.item;
        return exception.copyWith(
          item: item == null
              ? null
              : _shiftMemoryItem(
                  item,
                  delta,
                  updatedAt: updatedAt,
                ),
          createdAt: exception.createdAt.add(delta),
          updatedAt: updatedAt,
        );
      },
    ).merge(
      localItems: recurrenceExceptions,
      remoteEntities: remoteEntities,
      replaceLocal: replaceRecurrenceExceptions,
    );
    final recurrenceSeriesOutcome =
        await EncryptedEntitySyncEngine<RecurrenceSeries>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.recurrenceSeries,
      idOf: (series) => series.id,
      updatedAtOf: (series) => series.updatedAt,
      toJson: (series) => series.toJson(),
      fromJson: RecurrenceSeries.fromJson,
      withCanonicalUpdatedAt: (series, updatedAt) {
        final delta = updatedAt.difference(series.updatedAt);
        return series.copyWith(
          template: _shiftMemoryItem(series.template, delta),
          createdAt: series.createdAt.add(delta),
          updatedAt: updatedAt,
        );
      },
    ).merge(
      localItems: recurrenceSeries,
      remoteEntities: remoteEntities,
      replaceLocal: replaceRecurrenceSeries,
    );
    final financeOutcome = await EncryptedEntitySyncEngine<FinanceEntry>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.financeEntry,
      idOf: (entry) => entry.id,
      updatedAtOf: (entry) => entry.updatedAt,
      toJson: (entry) => entry.toJson(),
      fromJson: FinanceEntry.fromJson,
      withCanonicalUpdatedAt: (entry, updatedAt) =>
          entry.copyWith(updatedAt: updatedAt),
    ).merge(
      localItems: financeEntries,
      remoteEntities: remoteEntities,
      replaceLocal: replaceFinanceEntries ?? (_) async {},
    );

    final toolCalculationsOutcome =
        await EncryptedEntitySyncEngine<SavedToolCalculation>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.toolCalculation,
      idOf: (calculation) => calculation.id,
      updatedAtOf: (calculation) => calculation.updatedAt,
      toJson: (calculation) => calculation.toJson(),
      fromJson: SavedToolCalculation.fromJson,
      withCanonicalUpdatedAt: (calculation, updatedAt) =>
          calculation.copyWith(updatedAt: updatedAt),
    ).merge(
      localItems: toolCalculations,
      remoteEntities: remoteEntities,
      replaceLocal: replaceToolCalculations ?? (_) async {},
    );
    // Закладка опознаётся статьёй справочника: своего идентификатора у неё
    // нет, и заводить второй было бы вторым именем одной и той же вещи.
    final toolBookmarksOutcome =
        await EncryptedEntitySyncEngine<ReferenceBookmark>(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
      kind: SyncEntityKind.toolBookmark,
      idOf: (bookmark) => bookmark.entryId,
      updatedAtOf: (bookmark) => bookmark.updatedAt,
      toJson: (bookmark) => bookmark.toJson(),
      fromJson: ReferenceBookmark.fromJson,
      withCanonicalUpdatedAt: (bookmark, updatedAt) =>
          bookmark.copyWith(updatedAt: updatedAt),
    ).merge(
      localItems: toolBookmarks,
      remoteEntities: remoteEntities,
      replaceLocal: replaceToolBookmarks ?? (_) async {},
    );

    await remote.applyEntities([
      ...memoryOutcome.changesToUpload,
      ...shiftsOutcome.changesToUpload,
      ...accountsOutcome.changesToUpload,
      ...recurrenceExceptionsOutcome.changesToUpload,
      ...recurrenceSeriesOutcome.changesToUpload,
      ...financeOutcome.changesToUpload,
      ...toolCalculationsOutcome.changesToUpload,
      ...toolBookmarksOutcome.changesToUpload,
    ]);
    return _combine([
      memoryOutcome.result,
      shiftsOutcome.result,
      accountsOutcome.result,
      recurrenceExceptionsOutcome.result,
      recurrenceSeriesOutcome.result,
      financeOutcome.result,
      toolCalculationsOutcome.result,
      toolBookmarksOutcome.result,
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

MemoryItem _canonicalMemoryItem(MemoryItem item, DateTime updatedAt) {
  return _shiftMemoryItem(
    item,
    updatedAt.difference(item.updatedAt),
    updatedAt: updatedAt,
  );
}

MemoryItem _shiftMemoryItem(
  MemoryItem item,
  Duration delta, {
  DateTime? updatedAt,
}) {
  final reminder = item.remindAt;
  return item.copyWith(
    createdAt: item.createdAt.add(delta),
    updatedAt: updatedAt ?? item.updatedAt.add(delta),
    remindAt: reminder?.add(delta),
  );
}
