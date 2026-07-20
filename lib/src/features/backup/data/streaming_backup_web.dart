import '../../accounts/domain/account_item.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../recurrence/domain/recurrence_series.dart';
import '../../recurrence/domain/recurrence_occurrence_exception.dart';
import '../../shift_schedules/domain/shift_schedule.dart';

Future<String?> createStreamingBackup({
  required String password,
  required String format,
  required int version,
  required List<MemoryItem> memoryItems,
  required List<ShiftSchedule> shiftSchedules,
  required List<AccountItem> accounts,
  required List<RecurrenceSeries> recurrenceSeries,
  required List<RecurrenceOccurrenceException> recurrenceExceptions,
  String? temporaryRoot,
}) async =>
    null;

Future<List<MemoryItem>> restoreStreamingMedia({
  required List<MemoryItem> items,
  required List<dynamic> mediaEntries,
  required Map<String, List<int>> archiveFiles,
}) async =>
    items;

Future<void> deleteStreamingBackup(String path) async {}
