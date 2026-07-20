import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'memory_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [MemoryItems, RecurrenceSeriesRows, SecureEntities])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(memoryItems, memoryItems.timeMinutes);
          }
          if (from < 3) {
            await migrator.addColumn(
              memoryItems,
              memoryItems.reminderSoundUri,
            );
            await migrator.addColumn(
              memoryItems,
              memoryItems.reminderSoundName,
            );
          }
          if (from < 4) {
            await migrator.createTable(secureEntities);
          }
          if (from < 5) {
            await migrator.addColumn(memoryItems, memoryItems.seriesId);
            await migrator.addColumn(memoryItems, memoryItems.amountMinor);
            await migrator.addColumn(
              memoryItems,
              memoryItems.paymentCategory,
            );
            await migrator.addColumn(memoryItems, memoryItems.birthYear);
            await migrator.addColumn(
              memoryItems,
              memoryItems.isGeneratedOccurrence,
            );
            await migrator.createTable(recurrenceSeriesRows);
          }
          if (from >= 5 && from < 6) {
            await migrator.addColumn(
              recurrenceSeriesRows,
              recurrenceSeriesRows.generatedThrough,
            );
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'ezhednevnik_v2.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
