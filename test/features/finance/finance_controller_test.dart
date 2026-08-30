import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/finance/state/finance_controller.dart';
import 'package:ezhednevnik_v2/src/features/finance/state/finance_month_ledger.dart';
import 'package:ezhednevnik_v2/src/features/finance/state/finance_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('add, edit, month move and delete preserve all currency journals',
      () async {
    final repository = _FinanceRepository([]);
    final sync = _RecordingSyncObserver();
    final controller = FinanceController(repository, sync);
    addTearDown(controller.dispose);
    await controller.load();
    final august = _entry('rub', '10', 'RUB', DateTime(2026, 8, 30));
    final usd = _entry('usd', '20', 'USD', DateTime(2026, 8, 30));

    await controller.add(august);
    await controller.add(usd);
    await controller.update(
      august.copyWith(
        amount: '12.50',
        occurredOn: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1, 12),
      ),
    );

    expect(controller.state, hasLength(2));
    expect(controller.state.singleWhere((entry) => entry.id == 'rub').amount,
        '12.5');
    expect(
      controller.state.singleWhere((entry) => entry.id == 'rub').occurredOn,
      DateTime(2026, 9, 1),
    );
    expect(controller.state.singleWhere((entry) => entry.id == 'usd').amount,
        '20');

    await controller.delete('rub');
    expect(controller.state.single.id, 'usd');
    expect((await repository.loadAll()).single.currencyCode, 'USD');
    expect(sync.financeChanges, 3);
    expect(sync.deletedFinanceIds, ['rub']);
    expect(sync.deletedAt.single, isNotNull);
  });

  test('selected currency is restored locally', () async {
    SharedPreferences.setMockInitialValues({});
    final first = FinanceCurrencyController();
    addTearDown(first.dispose);
    await first.select('USD');
    final second = FinanceCurrencyController();
    addTearDown(second.dispose);
    await second.load();

    expect(second.state, 'USD');
  });

  test('month ledger carries balance forward and excludes future operations',
      () {
    FinanceEntry operation(
      String id,
      FinanceEntryKind kind,
      String amount,
      String currency,
      DateTime date,
    ) {
      return FinanceEntry(
        id: id,
        kind: kind,
        amount: amount,
        currencyCode: currency,
        category: 'Test',
        occurredOn: date,
        createdAt: date,
        updatedAt: date,
      );
    }

    final entries = [
      operation(
        'before',
        FinanceEntryKind.income,
        '100',
        'RUB',
        DateTime(2026, 7, 31),
      ),
      operation(
        'current',
        FinanceEntryKind.expense,
        '20',
        'RUB',
        DateTime(2026, 8, 10),
      ),
      operation(
        'future',
        FinanceEntryKind.expense,
        '30',
        'RUB',
        DateTime(2026, 9, 1),
      ),
      operation(
        'other-currency',
        FinanceEntryKind.income,
        '500',
        'USD',
        DateTime(2026, 8, 1),
      ),
    ];

    final august = FinanceMonthLedger.build(
      allEntries: entries,
      currencyCode: 'RUB',
      month: DateTime(2026, 8),
    );
    final september = FinanceMonthLedger.build(
      allEntries: entries,
      currencyCode: 'RUB',
      month: DateTime(2026, 9),
    );

    expect(august.entries.map((entry) => entry.id), ['current']);
    expect(august.summary.income.toString(), '0');
    expect(august.summary.expense.toString(), '20');
    expect(august.summary.balance.toString(), '80');
    expect(september.entries.map((entry) => entry.id), ['future']);
    expect(september.summary.balance.toString(), '50');
  });
}

class _RecordingSyncObserver extends NoopSyncMutationObserver {
  int financeChanges = 0;
  final deletedFinanceIds = <String>[];
  final deletedAt = <DateTime>[];

  @override
  void financeEntriesChanged() {
    financeChanges += 1;
  }

  @override
  Future<void> financeEntryDeleted(String id, DateTime deletedAt) async {
    deletedFinanceIds.add(id);
    this.deletedAt.add(deletedAt);
  }
}

class _FinanceRepository implements FinanceRepository {
  _FinanceRepository(this.entries);

  List<FinanceEntry> entries;

  @override
  Future<List<FinanceEntry>> loadAll() async => List.of(entries);

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {
    this.entries = List.of(entries);
  }
}

FinanceEntry _entry(String id, String amount, String currency, DateTime date) {
  return FinanceEntry(
    id: id,
    kind: FinanceEntryKind.expense,
    amount: amount,
    currencyCode: currency,
    category: 'Test',
    occurredOn: date,
    createdAt: date,
    updatedAt: date,
  );
}
