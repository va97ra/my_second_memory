import 'package:drift/native.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_data/ez_data_io.dart';

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
      historyThrough: DateTime(2028, 7, 20),
      subscriptionEndDate: DateTime(2027, 7, 20),
    );

    await repository.upsert(series);
    final restored = await repository.loadAll();

    expect(restored.single.template.birthYear, 1985);
    expect(restored.single.historyThrough, DateTime(2028, 7, 20));
    expect(restored.single.subscriptionEndDate, DateTime(2027, 7, 20));
    await repository.delete(series.id);
    expect(await repository.loadAll(), isEmpty);
    await repository.close();
  });
}
