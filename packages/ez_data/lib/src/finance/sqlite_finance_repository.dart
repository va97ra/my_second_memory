import 'package:drift/drift.dart';
import 'package:ez_domain/ez_domain.dart';

import '../database/app_database.dart';
import 'finance_repository.dart';

class SqliteFinanceRepository implements FinanceRepository {
  SqliteFinanceRepository(this._database, [this._closeDatabase = true]);

  final AppDatabase _database;
  final bool _closeDatabase;

  @override
  Future<List<FinanceEntry>> loadAll() async {
    final rows = await _database.select(_database.financeEntries).get();
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {
    await _database.transaction(() async {
      await _database.delete(_database.financeEntries).go();
      if (entries.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.financeEntries,
            [for (final entry in entries) _toCompanion(entry)],
          );
        });
      }
    });
  }

  @override
  Future<void> upsertAll(List<FinanceEntry> entries) async {
    if (entries.isEmpty) return;
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.financeEntries,
        [for (final entry in entries) _toCompanion(entry)],
      );
    });
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_database.delete(_database.financeEntries)
          ..where((row) => row.id.isIn(ids)))
        .go();
  }

  FinanceEntriesCompanion _toCompanion(FinanceEntry entry) {
    return FinanceEntriesCompanion.insert(
      id: entry.id,
      kind: entry.kind.name,
      amount: entry.amount,
      currencyCode: entry.currencyCode,
      category: entry.category,
      description: Value(entry.description),
      occurredOn: entry.occurredOn,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  FinanceEntry _fromRow(FinanceEntryRow row) => FinanceEntry(
        id: row.id,
        kind: FinanceEntryKind.values.byName(row.kind),
        amount: row.amount,
        currencyCode: row.currencyCode,
        category: row.category,
        description: row.description,
        occurredOn: row.occurredOn,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  Future<void> close() =>
      _closeDatabase ? _database.close() : Future<void>.value();
}
