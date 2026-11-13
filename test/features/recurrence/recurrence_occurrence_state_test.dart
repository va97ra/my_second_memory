import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/provider_test_support.dart';

/// Проверяет обещания docs/behavior.md о состоянии одного вхождения повтора:
/// выполнение, архивация и восстановление касаются только его, а не серии.
Future<Records> _environment() => loadRecords(testContainer());

Future<RecurrenceSeries> _startedSeries(Records env) async {
  final start = DateTime(2026, 3, 10);
  final record = MemoryItem(
    id: 'origin',
    type: MemoryType.payment,
    title: 'Интернет',
    body: 'Интернет',
    memoryDate: start,
    createdAt: start,
    updatedAt: start,
    amountMinor: 99900,
  );
  await env.memories.add(record);
  return env.series.setFrequency(record, RecurrenceFrequency.monthly);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('marking one occurrence done leaves the others alone', () async {
    final env = await _environment();
    final series = await _startedSeries(env);
    final june = occurrenceFromSeries(series, DateTime(2026, 6, 10));

    await env.series.toggleOccurrenceDone(june);

    final marker = env.exceptions.exceptions.single;
    expect(marker.occurrenceDate, DateTime(2026, 6, 10));
    expect(marker.item?.status, MemoryStatus.done);
    // Шаблон серии остаётся активным: следующий месяц приходит невыполненным.
    expect(env.series.state.single.template.status, MemoryStatus.active);

    final july = occurrenceFromSeries(
      env.series.state.single,
      DateTime(2026, 7, 10),
    );
    expect(july.status, MemoryStatus.active);
  });

  test('marking it done twice returns it to active', () async {
    final env = await _environment();
    final series = await _startedSeries(env);
    final june = occurrenceFromSeries(series, DateTime(2026, 6, 10));

    await env.series.toggleOccurrenceDone(june);
    final done = env.exceptions.exceptions.single.item!;
    await env.series.toggleOccurrenceDone(done);

    expect(
      env.exceptions.exceptions.single.item?.status,
      MemoryStatus.active,
    );
  });

  test(
      'archiving an occurrence hides only that one, and restore brings it '
      'back', () async {
    final env = await _environment();
    final series = await _startedSeries(env);
    final june = occurrenceFromSeries(series, DateTime(2026, 6, 10));

    await env.series.archiveOccurrence(june);
    expect(
      env.exceptions.exceptions.single.item?.status,
      MemoryStatus.archived,
    );
    expect(env.series.state.single.template.status, MemoryStatus.active);

    final archived = env.exceptions.exceptions.single.item!;
    await env.series.restoreOccurrence(archived);
    expect(
      env.exceptions.exceptions.single.item?.status,
      MemoryStatus.active,
    );
  });
}
