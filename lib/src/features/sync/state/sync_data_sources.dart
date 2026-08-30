import 'package:ez_domain/ez_domain.dart';

/// Что именно синхронизируется и как это читать и записывать.
///
/// Контроллер синхронизации не знает ни про репозитории, ни про контроллеры
/// приложения: он получает набор функций. Виды данных, которых нет в сборке,
/// заменяются пустыми — тогда синхронизация просто их не касается.
class SyncDataSources {
  SyncDataSources({
    required this.readMemoryItems,
    required Future<void> Function(List<MemoryItem>) replaceMemoryItems,
    Future<void> Function(List<MemoryItem>, List<MemoryItem>)? mergeMemoryItems,
    Future<List<ShiftSchedule>> Function()? readShiftSchedules,
    Future<void> Function(List<ShiftSchedule>)? replaceShiftSchedules,
    Future<List<AccountItem>> Function()? readAccounts,
    Future<void> Function(List<AccountItem>)? replaceAccounts,
    Future<List<RecurrenceSeries>> Function()? readRecurrenceSeries,
    Future<void> Function(List<RecurrenceSeries>)? replaceRecurrenceSeries,
    Future<void> Function(List<RecurrenceSeries>, List<RecurrenceSeries>)?
        mergeRecurrenceSeries,
    Future<List<RecurrenceOccurrenceException>> Function()?
        readRecurrenceExceptions,
    Future<void> Function(List<RecurrenceOccurrenceException>)?
        replaceRecurrenceExceptions,
    Future<void> Function(
      List<RecurrenceOccurrenceException>,
      List<RecurrenceOccurrenceException>,
    )? mergeRecurrenceExceptions,
    Future<List<FinanceEntry>> Function()? readFinanceEntries,
    Future<void> Function(List<FinanceEntry>)? replaceFinanceEntries,
    Future<void> Function(List<FinanceEntry>, List<FinanceEntry>)?
        mergeFinanceEntries,
  })  :
        // Слияние знает, с чем сравнивать, а замена — нет. Там, где слияния не
        // дали, приходящее просто заменяет то, что лежало.
        mergeMemoryItems =
            mergeMemoryItems ?? ((items, _) => replaceMemoryItems(items)),
        readShiftSchedules = readShiftSchedules ?? _noShiftSchedules,
        replaceShiftSchedules = replaceShiftSchedules ?? _ignoreShiftSchedules,
        readAccounts = readAccounts ?? _noAccounts,
        replaceAccounts = replaceAccounts ?? _ignoreAccounts,
        readRecurrenceSeries = readRecurrenceSeries ?? _noRecurrenceSeries,
        mergeRecurrenceSeries = mergeRecurrenceSeries ??
            ((items, _) =>
                (replaceRecurrenceSeries ?? _ignoreRecurrenceSeries)(items)),
        readRecurrenceExceptions =
            readRecurrenceExceptions ?? _noRecurrenceExceptions,
        mergeRecurrenceExceptions = mergeRecurrenceExceptions ??
            ((items, _) =>
                (replaceRecurrenceExceptions ?? _ignoreRecurrenceExceptions)(
                  items,
                )),
        readFinanceEntries = readFinanceEntries ?? _noFinanceEntries,
        mergeFinanceEntries = mergeFinanceEntries ??
            ((entries, _) =>
                (replaceFinanceEntries ?? _ignoreFinanceEntries)(entries));

  final Future<List<MemoryItem>> Function() readMemoryItems;
  final Future<void> Function(List<MemoryItem>, List<MemoryItem>)
      mergeMemoryItems;
  final Future<List<ShiftSchedule>> Function() readShiftSchedules;
  final Future<void> Function(List<ShiftSchedule>) replaceShiftSchedules;
  final Future<List<AccountItem>> Function() readAccounts;
  final Future<void> Function(List<AccountItem>) replaceAccounts;
  final Future<List<RecurrenceSeries>> Function() readRecurrenceSeries;
  final Future<void> Function(List<RecurrenceSeries>, List<RecurrenceSeries>)
      mergeRecurrenceSeries;
  final Future<List<RecurrenceOccurrenceException>> Function()
      readRecurrenceExceptions;
  final Future<void> Function(
    List<RecurrenceOccurrenceException>,
    List<RecurrenceOccurrenceException>,
  ) mergeRecurrenceExceptions;
  final Future<List<FinanceEntry>> Function() readFinanceEntries;
  final Future<void> Function(List<FinanceEntry>, List<FinanceEntry>)
      mergeFinanceEntries;
}

Future<List<ShiftSchedule>> _noShiftSchedules() async => const [];

Future<void> _ignoreShiftSchedules(List<ShiftSchedule> _) async {}

Future<List<AccountItem>> _noAccounts() async => const [];

Future<void> _ignoreAccounts(List<AccountItem> _) async {}

Future<List<RecurrenceSeries>> _noRecurrenceSeries() async => const [];

Future<void> _ignoreRecurrenceSeries(List<RecurrenceSeries> _) async {}

Future<List<RecurrenceOccurrenceException>> _noRecurrenceExceptions() async =>
    const [];

Future<void> _ignoreRecurrenceExceptions(
  List<RecurrenceOccurrenceException> _,
) async {}

Future<List<FinanceEntry>> _noFinanceEntries() async => const [];

Future<void> _ignoreFinanceEntries(List<FinanceEntry> _) async {}
