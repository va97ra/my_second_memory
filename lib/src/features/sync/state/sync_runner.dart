import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

import 'sync_data_sources.dart';

/// Один прогон синхронизации.
///
/// Читает всё, что синхронизируется, отдаёт это движку и записывает
/// пришедшее обратно. Ни о состоянии экрана, ни о том, когда прогон
/// запускается, здесь не знают.
class SyncRunner {
  const SyncRunner({
    required this.remote,
    required this.tombstones,
    required this.data,
  });

  final SyncRemoteStore remote;
  final SyncTombstoneStore tombstones;
  final SyncDataSources data;

  Future<SyncRunResult> run(AppCipher cipher) async {
    // Всё читается до слияния: движку нужно и то, что лежит сейчас, и то, что
    // лежало до его правок, — иначе он не отличит чужое изменение от своего.
    final memoryItems = await data.readMemoryItems();
    final shiftSchedules = await data.readShiftSchedules();
    final accounts = await data.readAccounts();
    final recurrenceSeries = await data.readRecurrenceSeries();
    final recurrenceExceptions = await data.readRecurrenceExceptions();
    final financeEntries = await data.readFinanceEntries();
    final toolCalculations = await data.readToolCalculations();
    final toolBookmarks = await data.readToolBookmarks();
    final learningRecords = await data.readLearningRecords();

    return AppSyncEngine(
      remote: remote,
      cipher: cipher,
      tombstones: tombstones,
    ).synchronize(
      memoryItems: memoryItems,
      replaceMemoryItems: (items) => data.mergeMemoryItems(items, memoryItems),
      shiftSchedules: shiftSchedules,
      replaceShiftSchedules: data.replaceShiftSchedules,
      accounts: accounts,
      replaceAccounts: data.replaceAccounts,
      recurrenceSeries: recurrenceSeries,
      replaceRecurrenceSeries: (items) =>
          data.mergeRecurrenceSeries(items, recurrenceSeries),
      recurrenceExceptions: recurrenceExceptions,
      replaceRecurrenceExceptions: (items) =>
          data.mergeRecurrenceExceptions(items, recurrenceExceptions),
      financeEntries: financeEntries,
      replaceFinanceEntries: (entries) =>
          data.mergeFinanceEntries(entries, financeEntries),
      toolCalculations: toolCalculations,
      replaceToolCalculations: (items) =>
          data.mergeToolCalculations(items, toolCalculations),
      toolBookmarks: toolBookmarks,
      replaceToolBookmarks: (items) =>
          data.mergeToolBookmarks(items, toolBookmarks),
      learningRecords: learningRecords,
      replaceLearningRecords: (items) =>
          data.mergeLearningRecords(items, learningRecords),
    );
  }
}
