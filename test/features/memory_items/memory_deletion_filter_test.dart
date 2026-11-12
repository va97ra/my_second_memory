import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';

/// Отметки удаления, которые считают свои чтения.
class _CountingDeletions extends NoopSyncMutationObserver {
  _CountingDeletions(this.deletions);

  final Map<String, DateTime> deletions;
  var fullReads = 0;

  @override
  Future<Map<String, DateTime>> memoryDeletions() async {
    fullReads++;
    return deletions;
  }
}

/// О2: перед слиянием отметки удаления читаются один раз, а не по разу на
/// каждую запись — каждое чтение разбирает весь список заново.
void main() {
  final date = DateTime(2026, 11, 12, 9);

  MemoryItem item(String id, {DateTime? updatedAt}) => MemoryItem(
        id: id,
        type: MemoryType.note,
        title: id,
        memoryDate: date,
        createdAt: date,
        updatedAt: updatedAt ?? date,
      );

  test('a thousand records read the deletions once', () async {
    final observer = _CountingDeletions(const {});
    final controller = MemoryItemsController(
      FakeMemoryRepository(const []),
      null,
      null,
      observer,
    );
    await controller.load();

    await controller.replaceAll([
      for (var index = 0; index < 1000; index++) item('record-$index'),
    ]);

    expect(controller.state, hasLength(1000));
    expect(observer.fullReads, 1);
  });

  test('a record deleted later stays deleted, one edited later comes back',
      () async {
    final deletedAt = date.add(const Duration(minutes: 5));
    final observer = _CountingDeletions({
      'stale': deletedAt,
      'revived': deletedAt,
    });
    final controller = MemoryItemsController(
      FakeMemoryRepository(const []),
      null,
      null,
      observer,
    );
    await controller.load();

    await controller.replaceAll([
      item('stale'),
      item('revived', updatedAt: deletedAt.add(const Duration(minutes: 1))),
      item('kept'),
    ]);

    expect(
      controller.state.map((entry) => entry.id),
      unorderedEquals(['revived', 'kept']),
    );
  });
}
