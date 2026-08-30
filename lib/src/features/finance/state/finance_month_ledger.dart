import 'package:ez_domain/ez_domain.dart';

/// Selected month operations and the balance carried through its final day.
class FinanceMonthLedger {
  const FinanceMonthLedger({
    required this.entries,
    required this.days,
    required this.summary,
  });

  final List<FinanceEntry> entries;
  final List<FinanceDayGroup> days;
  final FinanceSummary summary;

  factory FinanceMonthLedger.build({
    required Iterable<FinanceEntry> allEntries,
    required String currencyCode,
    required DateTime month,
  }) {
    final monthStart = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    final current = <FinanceEntry>[];
    final throughMonth = <FinanceEntry>[];

    for (final entry in allEntries) {
      if (entry.currencyCode != currencyCode ||
          !entry.occurredOn.isBefore(nextMonth)) {
        continue;
      }
      throughMonth.add(entry);
      if (!entry.occurredOn.isBefore(monthStart)) current.add(entry);
    }

    return FinanceMonthLedger(
      entries: List.unmodifiable(current),
      days: FinanceDayGroup.fromEntries(current),
      summary: FinanceSummary.forEntries(
        current,
        balanceEntries: throughMonth,
      ),
    );
  }
}

/// One ledger date split into the two visual income and expense columns.
class FinanceDayGroup {
  const FinanceDayGroup({
    required this.date,
    required this.incomes,
    required this.expenses,
  });

  final DateTime date;
  final List<FinanceEntry> incomes;
  final List<FinanceEntry> expenses;

  static List<FinanceDayGroup> fromEntries(Iterable<FinanceEntry> entries) {
    final days = <DateTime,
        ({List<FinanceEntry> incomes, List<FinanceEntry> expenses})>{};
    for (final entry in entries) {
      final date = DateTime(
        entry.occurredOn.year,
        entry.occurredOn.month,
        entry.occurredOn.day,
      );
      final day = days.putIfAbsent(
        date,
        () => (incomes: <FinanceEntry>[], expenses: <FinanceEntry>[]),
      );
      (entry.kind == FinanceEntryKind.income ? day.incomes : day.expenses)
          .add(entry);
    }
    return List.unmodifiable([
      for (final day in days.entries)
        FinanceDayGroup(
          date: day.key,
          incomes: List.unmodifiable(day.value.incomes),
          expenses: List.unmodifiable(day.value.expenses),
        ),
    ]);
  }
}
