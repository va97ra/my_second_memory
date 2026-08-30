import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finance entries normalize amounts and sum without doubles', () {
    final now = DateTime(2026, 8, 30);
    FinanceEntry entry(FinanceEntryKind kind, String amount) => FinanceEntry(
          id: '$kind-$amount',
          kind: kind,
          amount: amount,
          currencyCode: 'RUB',
          category: 'Другое',
          occurredOn: now,
          createdAt: now,
          updatedAt: now,
        );

    final summary = FinanceSummary.forEntries([
      entry(FinanceEntryKind.income, '0,10'),
      entry(FinanceEntryKind.income, '0.20'),
      entry(FinanceEntryKind.expense, '0.05'),
    ]);

    expect(summary.income.toString(), '0.3');
    expect(summary.expense.toString(), '0.05');
    expect(summary.balance.toString(), '0.25');
  });
}
