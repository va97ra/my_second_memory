import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Правило слияния одно на все виды данных, поэтому и проверяется один раз,
/// на простейшей записи, а не через шесть контроллеров.
class _Row {
  const _Row(this.id, this.updatedAt);

  final String id;
  final DateTime updatedAt;
}

void main() {
  final base = DateTime.utc(2026, 8, 30, 9);
  List<_Row> merge({
    required List<_Row> incoming,
    required List<_Row> current,
    required List<_Row> baseline,
  }) {
    return mergeSyncedEntities(
      incoming: incoming,
      current: current,
      baseline: baseline,
      idOf: (row) => row.id,
      updatedAtOf: (row) => row.updatedAt,
    );
  }

  test('what arrived newer replaces what lay untouched', () {
    final merged = merge(
      incoming: [_Row('a', base.add(const Duration(minutes: 5)))],
      current: [_Row('a', base)],
      baseline: [_Row('a', base)],
    );

    expect(merged.single.updatedAt, base.add(const Duration(minutes: 5)));
  });

  test('a row deleted while the run was in flight does not come back', () {
    final merged = merge(
      incoming: [_Row('a', base)],
      current: const [],
      baseline: [_Row('a', base)],
    );

    expect(merged, isEmpty);
  });

  test('a row edited during the run beats an older arrival', () {
    final merged = merge(
      incoming: [_Row('a', base.add(const Duration(minutes: 1)))],
      current: [_Row('a', base.add(const Duration(minutes: 9)))],
      baseline: [_Row('a', base)],
    );

    expect(merged.single.updatedAt, base.add(const Duration(minutes: 9)));
  });

  test('a row created during the run survives the merge', () {
    final merged = merge(
      incoming: const [],
      current: [_Row('new', base)],
      baseline: const [],
    );

    expect(merged.single.id, 'new');
  });
}
