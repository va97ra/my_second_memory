import 'package:cryptography/cryptography.dart';

import 'package:ez_domain/ez_domain.dart';

Future<String?> createStreamingBackup({
  required String password,
  required String format,
  required int version,
  required List<MemoryItem> memoryItems,
  required List<ShiftSchedule> shiftSchedules,
  required List<AccountItem> accounts,
  required List<RecurrenceSeries> recurrenceSeries,
  required List<RecurrenceOccurrenceException> recurrenceExceptions,
  required List<FinanceEntry> financeEntries,
  required ToolDataSnapshot toolData,
  String? temporaryRoot,
}) async =>
    null;

Future<List<MemoryItem>> restoreStreamingMedia({
  required List<MemoryItem> items,
  required List<dynamic> mediaEntries,
  required Map<String, List<int>> archiveFiles,
  SecretKey? encryptionKey,
}) async =>
    items;

Future<void> deleteStreamingBackup(String path) async {}
