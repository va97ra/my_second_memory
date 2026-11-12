import 'package:ez_domain/ez_domain.dart';
import '../security/app_cipher.dart';
import 'sync_local_store.dart';
import 'sync_remote_store.dart';
import 'cloud_snapshot.dart';
import 'encrypted_entity_sync_engine.dart';
import 'media_sync_engine.dart';

class AppSyncEngine {
  const AppSyncEngine({
    required this.remote,
    required this.cipher,
    required this.tombstones,
    this.media,
    this.snapshot,
  });

  final SyncRemoteStore remote;
  final AppCipher cipher;
  final SyncTombstoneStore tombstones;

  /// Вложения. Null означает, что на этой платформе файлов нет — в вебе
  /// снимок живёт строкой внутри самой записи и уезжает вместе с ней.
  final MediaSyncEngine? media;

  /// Облако, прочитанное прошлыми прогонами. Без него облако читается
  /// целиком, как при первом прогоне после запуска.
  final CloudSnapshot? snapshot;

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
  }) async {
    final cloud = snapshot ?? CloudSnapshot();
    final remoteEntities = await cloud.refresh(remote);
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

    var shiftsOutcome = await shiftsEngine.merge(
      localItems: shiftSchedules,
      remoteEntities: remoteEntities,
      replaceLocal: replaceShiftSchedules,
    );
    final shiftDeduplication = deduplicateShiftSchedules(shiftsOutcome.merged);
    if (shiftDeduplication.duplicateIds.isNotEmpty) {
      final userId = remote.currentUserId!;
      var deletedAt = DateTime.now();
      for (final schedule in shiftsOutcome.merged) {
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

      await replaceShiftSchedules(shiftDeduplication.schedules);
      final cleanupOutcome = await shiftsEngine.merge(
        localItems: shiftDeduplication.schedules,
        remoteEntities: remoteEntities,
        replaceLocal: replaceShiftSchedules,
      );
      shiftsOutcome = EntitySyncOutcome(
        result: SyncRunResult(
          downloaded: shiftsOutcome.result.downloaded,
          uploaded: cleanupOutcome.result.uploaded,
          deleted: shiftsOutcome.result.deleted +
              shiftDeduplication.duplicateIds.length,
        ),
        changesToUpload: cleanupOutcome.changesToUpload,
        merged: cleanupOutcome.merged,
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
    await _upload(cloud, [
      ...memoryOutcome.changesToUpload,
      ...shiftsOutcome.changesToUpload,
      ...accountsOutcome.changesToUpload,
      ...recurrenceExceptionsOutcome.changesToUpload,
      ...recurrenceSeriesOutcome.changesToUpload,
      ...financeOutcome.changesToUpload,
      ...toolCalculationsOutcome.changesToUpload,
    ]);
    // Вложения идут после записей: пока запись не слита, неизвестно, какие
    // файлы ей нужны и какие в облаке уже ничьи. Хозяева файлов — не только
    // записи, но и шаблоны серий и правки дат.
    final mediaReferences = mediaReferencesOf(
      items: memoryOutcome.merged,
      series: recurrenceSeriesOutcome.merged,
      exceptions: recurrenceExceptionsOutcome.merged,
    );
    // Сверка листает весь бакет, поэтому идёт, только когда есть что
    // сверять: набор ссылок изменился или прошлая сверка не довезла файлы.
    final media = this.media;
    final mediaResult = media == null || cloud.mediaSettled(mediaReferences)
        ? null
        : await media.synchronize(
            mediaReferences,
            referencesComplete: _coversCloud(remoteEntities, {
              SyncEntityKind.memoryItem: {
                for (final item in memoryOutcome.merged) item.id,
              },
              SyncEntityKind.recurrenceSeries: {
                for (final series in recurrenceSeriesOutcome.merged) series.id,
              },
              SyncEntityKind.recurrenceException: {
                for (final exception in recurrenceExceptionsOutcome.merged)
                  exception.id,
              },
            }),
          );
    if (mediaResult != null &&
        mediaResult.mediaFailed == 0 &&
        mediaResult.mediaMissing == 0) {
      cloud.settleMedia(mediaReferences);
    }
    return _combine([
      if (mediaResult != null) mediaResult,
      memoryOutcome.result,
      shiftsOutcome.result,
      accountsOutcome.result,
      recurrenceExceptionsOutcome.result,
      recurrenceSeriesOutcome.result,
      financeOutcome.result,
      toolCalculationsOutcome.result,
    ]);
  }

  /// Есть ли у каждой живой облачной строки, способной держать файлы, пара
  /// в слитых данных — то есть заведомо ли полны ссылки на вложения.
  ///
  /// Пары нет у строки, которую здесь удалили, а облако об этом ещё не
  /// узнало: тогда её файлы уйдут следующим прогоном. Всё прочее — ошибка
  /// где-то ещё, и тем более не повод удалять.
  static bool _coversCloud(
    List<SyncRemoteEntity> cloud,
    Map<SyncEntityKind, Set<String>> merged,
  ) {
    for (final row in cloud) {
      if (row.isDeleted) continue;
      final ids = merged[row.kind];
      if (ids != null && !ids.contains(row.entityId)) return false;
    }
    return true;
  }

  /// Сколько изменений уходит одним вызовом.
  static const uploadBatchSize = 200;

  /// Отправляет изменения пачками, каждую своим вызовом со своим таймаутом.
  ///
  /// Первая заливка большого дневника одним вызовом не укладывалась в
  /// таймаут и повторялась целиком. Пачки независимы: если оборвалась одна,
  /// отправленные до неё уже в облаке, а остальное следующий прогон найдёт
  /// сам — слияние видит, чего в облаке нет.
  Future<void> _upload(
    CloudSnapshot cloud,
    List<SyncRemoteEntity> changes,
  ) async {
    for (var start = 0; start < changes.length; start += uploadBatchSize) {
      final end = start + uploadBatchSize < changes.length
          ? start + uploadBatchSize
          : changes.length;
      final batch = changes.sublist(start, end);
      await remote.applyEntities(batch);
      cloud.recordSent(batch);
    }
  }

  SyncRunResult _combine(List<SyncRunResult> results) {
    return SyncRunResult(
      downloaded: results.fold(0, (total, item) => total + item.downloaded),
      uploaded: results.fold(0, (total, item) => total + item.uploaded),
      deleted: results.fold(0, (total, item) => total + item.deleted),
      mediaDownloaded:
          results.fold(0, (total, item) => total + item.mediaDownloaded),
      mediaUploaded:
          results.fold(0, (total, item) => total + item.mediaUploaded),
      mediaFailed: results.fold(0, (total, item) => total + item.mediaFailed),
      mediaMissing: results.fold(0, (total, item) => total + item.mediaMissing),
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
