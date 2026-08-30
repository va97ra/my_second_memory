import 'dart:io';

import 'package:drift/native.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_data/ez_data_io.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sqlite finance entries survive reopening without losing decimals',
      () async {
    final directory = await Directory.systemTemp.createTemp('finance_sqlite_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finance.sqlite');
    final entry = _entry('native', '1234567890.123456789', 'RUB');

    final firstDatabase = AppDatabase(NativeDatabase(file));
    await SqliteFinanceRepository(firstDatabase, false).replaceAll([entry]);
    await firstDatabase.close();

    final secondDatabase = AppDatabase(NativeDatabase(file));
    addTearDown(secondDatabase.close);
    final restored =
        await SqliteFinanceRepository(secondDatabase, false).loadAll();

    expect(restored.single.amount, '1234567890.123456789');
    expect(restored.single.currencyCode, 'RUB');
  });

  test('database upgrade from schema 9 creates the finance table', () async {
    final directory = await Directory.systemTemp.createTemp('finance_v9_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/v9.sqlite');
    final oldDatabase = AppDatabase(NativeDatabase(file));
    await oldDatabase.customStatement('DROP TABLE finance_entries');
    await oldDatabase.customStatement('PRAGMA user_version = 9');
    await oldDatabase.close();

    final database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    final repository = SqliteFinanceRepository(database, false);
    await repository.replaceAll([_entry('migrated', '1.25', 'USD')]);

    expect((await repository.loadAll()).single.id, 'migrated');
    expect(database.schemaVersion, 10);
  });

  test('SharedPreferences fallback restores independent currency journals',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalFinanceRepository(preferences: preferences);
    await repository.replaceAll([
      _entry('rub', '10.10', 'RUB'),
      _entry('usd', '20.20', 'USD'),
    ]);

    final restored =
        await LocalFinanceRepository(preferences: preferences).loadAll();

    expect(restored.map((entry) => entry.currencyCode), ['RUB', 'USD']);
    expect(restored.map((entry) => entry.amount), ['10.1', '20.2']);
  });
}

FinanceEntry _entry(String id, String amount, String currency) {
  final date = DateTime.utc(2026, 8, 30);
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
