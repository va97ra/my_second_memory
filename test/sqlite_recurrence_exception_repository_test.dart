import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data_io.dart';

void main() {
  test('SQLite stores and removes recurrence exceptions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = SqliteRecurrenceExceptionRepository(database, false);
    final date = DateTime(2026, 7, 20);

    await repository.skip('series', date);
    final loaded = await repository.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.single.kind, RecurrenceOccurrenceExceptionKind.skipped);

    await repository.delete('series', date);
    expect(await repository.loadAll(), isEmpty);
    await database.close();
  });
}
