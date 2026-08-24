import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'package:ez_domain/ez_domain.dart';
import 'recurrence_repository.dart';

class SqliteRecurrenceRepository implements RecurrenceRepository {
  SqliteRecurrenceRepository([
    AppDatabase? database,
    bool closeDatabase = true,
  ])  : _database = database ?? AppDatabase(),
        _closeDatabase = closeDatabase;

  final AppDatabase _database;
  final bool _closeDatabase;

  @override
  Future<List<RecurrenceSeries>> loadAll() async {
    final rows = await _database.select(_database.recurrenceSeriesRows).get();
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  Future<void> upsert(RecurrenceSeries series) async {
    await _database
        .into(_database.recurrenceSeriesRows)
        .insertOnConflictUpdate(_toCompanion(series));
  }

  @override
  Future<void> upsertAll(List<RecurrenceSeries> series) async {
    if (series.isEmpty) return;
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.recurrenceSeriesRows,
        [for (final item in series) _toCompanion(item)],
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(_database.recurrenceSeriesRows)
          ..where((row) => row.id.equals(id)))
        .go();
  }

  @override
  Future<void> replaceAll(List<RecurrenceSeries> series) async {
    await _database.transaction(() async {
      await _database.delete(_database.recurrenceSeriesRows).go();
      if (series.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.recurrenceSeriesRows,
            [for (final item in series) _toCompanion(item)],
          );
        });
      }
    });
  }

  RecurrenceSeriesRowsCompanion _toCompanion(RecurrenceSeries series) {
    return RecurrenceSeriesRowsCompanion.insert(
      id: series.id,
      frequency: series.frequency.name,
      templateJson: jsonEncode(series.template.toJson()),
      startDate: series.startDate,
      originItemId: series.originItemId,
      isEnabled: Value(series.isEnabled),
      createdAt: series.createdAt,
      updatedAt: series.updatedAt,
      endDate: Value(series.endDate),
      subscriptionEndDate: Value(series.subscriptionEndDate),
      historyThrough: Value(series.historyThrough),
    );
  }

  RecurrenceSeries _fromRow(RecurrenceSeriesRow row) {
    return RecurrenceSeries(
      id: row.id,
      frequency: RecurrenceFrequency.values.byName(row.frequency),
      template: MemoryItem.fromJson(
        Map<String, Object?>.from(jsonDecode(row.templateJson) as Map),
      ),
      startDate: row.startDate,
      originItemId: row.originItemId,
      isEnabled: row.isEnabled,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      endDate: row.endDate,
      subscriptionEndDate: row.subscriptionEndDate,
      historyThrough: row.historyThrough,
    );
  }

  @override
  Future<void> close() =>
      _closeDatabase ? _database.close() : Future<void>.value();
}
