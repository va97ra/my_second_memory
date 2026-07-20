import 'package:drift/native.dart';
import 'package:ezhednevnik_v2/src/data/database/app_database.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/sqlite_recurrence_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sqlite recurrence repository stores and removes a series', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = SqliteRecurrenceRepository(database);
    final date = DateTime(2026, 7, 20);
    final template = MemoryItem(
      id: 'birthday',
      type: MemoryType.birthday,
      title: 'Анна',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      birthYear: 1985,
    );
    final series = RecurrenceSeries(
      id: 'annual',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: date,
      originItemId: template.id,
      createdAt: date,
      updatedAt: date,
      generatedThrough: DateTime(2028, 7, 20),
    );

    await repository.upsert(series);
    final restored = await repository.loadAll();

    expect(restored.single.template.birthYear, 1985);
    expect(restored.single.generatedThrough, DateTime(2028, 7, 20));
    await repository.delete(series.id);
    expect(await repository.loadAll(), isEmpty);
    await repository.close();
  });
}
