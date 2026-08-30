import 'package:decimal/decimal.dart';

import 'finance_entry.dart';

class FinanceSummary {
  const FinanceSummary({
    required this.income,
    required this.expense,
    required this.balance,
  });

  final Decimal income;
  final Decimal expense;
  final Decimal balance;

  factory FinanceSummary.forEntries(
    Iterable<FinanceEntry> entries, {
    Iterable<FinanceEntry>? balanceEntries,
  }) {
    var income = Decimal.zero;
    var expense = Decimal.zero;
    for (final entry in entries) {
      final amount = Decimal.parse(entry.amount);
      if (entry.kind == FinanceEntryKind.income) {
        income += amount;
      } else {
        expense += amount;
      }
    }
    var balance = income - expense;
    if (balanceEntries != null) {
      balance = Decimal.zero;
      for (final entry in balanceEntries) {
        final amount = Decimal.parse(entry.amount);
        balance += entry.kind == FinanceEntryKind.income ? amount : -amount;
      }
    }
    return FinanceSummary(
      income: income,
      expense: expense,
      balance: balance,
    );
  }
}
