import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';
import '../../memory_items/domain/memory_item.dart';
import '../domain/recurrence_occurrence_exception.dart';
import 'recurrence_exception_repository.dart';

class SqliteRecurrenceExceptionRepository
    implements RecurrenceExceptionRepository {
  SqliteRecurrenceExceptionRepository([
    AppDatabase? database,
    bool closeDatabase = true,
  ])  : _database = database ?? AppDatabase(),
        _closeDatabase = closeDatabase;

  final AppDatabase _database;
  final bool _closeDatabase;

  @override
  Future<List<RecurrenceOccurrenceException>> loadAll() async {
    final rows = await _database
        .select(_database.recurrenceOccurrenceExceptionRows)
        .get();
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  Future<void> upsert(RecurrenceOccurrenceException exception) async {
    await _database
        .into(_database.recurrenceOccurrenceExceptionRows)
        .insertOnConflictUpdate(_toCompanion(exception));
  }

  @override
  Future<void> upsertAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    if (exceptions.isEmpty) return;
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.recurrenceOccurrenceExceptionRows,
        [for (final exception in exceptions) _toCompanion(exception)],
      );
    });
  }

  @override
  Future<RecurrenceOccurrenceException> skip(
    String seriesId,
    DateTime occurrenceDate,
  ) async {
    final now = DateTime.now();
    final date = DateTime(
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
    );
    final exception = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(seriesId, date),
      seriesId: seriesId,
      occurrenceDate: date,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      createdAt: now,
      updatedAt: now,
    );
    await upsert(exception);
    return exception;
  }

  @override
  Future<void> delete(String seriesId, DateTime occurrenceDate) async {
    await (_database.delete(_database.recurrenceOccurrenceExceptionRows)
          ..where((row) => row.id.equals(
                recurrenceExceptionId(seriesId, occurrenceDate),
              )))
        .go();
  }

  @override
  Future<void> deleteSeries(String seriesId) async {
    await (_database.delete(_database.recurrenceOccurrenceExceptionRows)
          ..where((row) => row.seriesId.equals(seriesId)))
        .go();
  }

  @override
  Future<void> replaceAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    await _database.transaction(() async {
      await _database.delete(_database.recurrenceOccurrenceExceptionRows).go();
      if (exceptions.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.recurrenceOccurrenceExceptionRows,
            [for (final exception in exceptions) _toCompanion(exception)],
          );
        });
      }
    });
  }

  RecurrenceOccurrenceExceptionRowsCompanion _toCompanion(
    RecurrenceOccurrenceException exception,
  ) {
    return RecurrenceOccurrenceExceptionRowsCompanion.insert(
      id: exception.id,
      seriesId: exception.seriesId,
      occurrenceDate: exception.occurrenceDate,
      kind: exception.kind.name,
      itemJson: Value(
        exception.item == null ? null : jsonEncode(exception.item!.toJson()),
      ),
      createdAt: exception.createdAt,
      updatedAt: exception.updatedAt,
    );
  }

  RecurrenceOccurrenceException _fromRow(
    RecurrenceOccurrenceExceptionRow row,
  ) {
    return RecurrenceOccurrenceException(
      id: row.id,
      seriesId: row.seriesId,
      occurrenceDate: row.occurrenceDate,
      kind: RecurrenceOccurrenceExceptionKind.values.byName(row.kind),
      item: row.itemJson == null
          ? null
          : MemoryItem.fromJson(
              Map<String, Object?>.from(jsonDecode(row.itemJson!) as Map),
            ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> close() =>
      _closeDatabase ? _database.close() : Future<void>.value();
}
