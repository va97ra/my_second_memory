import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';

import '../database/app_database.dart';
import 'tool_data_repository.dart';

class SqliteToolDataRepository implements ToolDataRepository {
  SqliteToolDataRepository(this._database, [this._closeDatabase = true]);

  final AppDatabase _database;
  final bool _closeDatabase;

  @override
  Future<ToolDataSnapshot> load() async {
    final rows = await _database.select(_database.toolDataRows).get();
    final calculations = <SavedToolCalculation>[];
    for (final row in rows) {
      final json = Map<String, Object?>.from(
        jsonDecode(row.payloadJson) as Map,
      );
      switch (row.kind) {
        case 'calculation':
          calculations.add(SavedToolCalculation.fromJson(json));
        default:
          // Строка удалённого инструмента: читать нечем, но открывать
          // хранилище она мешать не должна.
          continue;
      }
    }
    calculations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return ToolDataSnapshot(calculations: calculations);
  }

  @override
  Future<void> replaceAll(ToolDataSnapshot snapshot) async {
    await _database.transaction(() async {
      await _database.delete(_database.toolDataRows).go();
      await _database.batch((batch) {
        batch.insertAll(_database.toolDataRows, [
          for (final item in snapshot.calculations)
            ToolDataRowsCompanion.insert(
              id: 'calculation:${item.id}',
              kind: 'calculation',
              payloadJson: jsonEncode(item.toJson()),
              updatedAt: item.updatedAt,
            ),
        ]);
      });
    });
  }

  Future<void> close() =>
      _closeDatabase ? _database.close() : Future<void>.value();
}
