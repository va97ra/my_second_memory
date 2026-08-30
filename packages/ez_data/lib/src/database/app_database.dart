import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'memory_tables.dart';
import 'finance_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  MemoryItems,
  RecurrenceSeriesRows,
  RecurrenceOccurrenceExceptionRows,
  SecureEntities,
  FinanceEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 10;

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
          if (from < 7) {
            if (from >= 5) {
              await migrator.addColumn(
                recurrenceSeriesRows,
                recurrenceSeriesRows.endDate,
              );
              await migrator.addColumn(
                recurrenceSeriesRows,
                recurrenceSeriesRows.historyThrough,
              );
            }
            await migrator.createTable(recurrenceOccurrenceExceptionRows);
          }
          if (from < 8) {
            await migrator.addColumn(memoryItems, memoryItems.isUndated);
          }
          if (from >= 5 && from < 9) {
            await migrator.addColumn(
              recurrenceSeriesRows,
              recurrenceSeriesRows.subscriptionEndDate,
            );
          }
          if (from < 10) {
            await migrator.createTable(financeEntries);
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
