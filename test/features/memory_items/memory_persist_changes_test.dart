import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/provider_test_support.dart';

/// О3: после слияния в хранилище уходит только разница. Переписывать всю
/// таблицу ради одной правки дорого, а при PIN это ещё и новое шифрование
/// каждой записи.
void main() {
  final date = DateTime(2026, 11, 12, 9);

  MemoryItem item(int index, {String? body, DateTime? updatedAt}) => MemoryItem(
        id: 'record-$index',
        type: MemoryType.note,
        title: 'Запись $index',
        body: body ?? 'Запись $index',
        memoryDate: date,
        createdAt: date,
        updatedAt: updatedAt ?? date,
      );

  final thousand = [for (var index = 0; index < 1000; index++) item(index)];

  Future<(MemoryItemsController, FakeMemoryRepository)> loaded() async {
    final repository = FakeMemoryRepository(List.of(thousand));
    final controller = testContainer(memories: repository)
        .read(memoryItemsControllerProvider.notifier);
    await controller.load();
    return (controller, repository);
  }

  test('one edit from the cloud writes one record', () async {
    final (controller, repository) = await loaded();
    final edited = item(
      42,
      body: 'Правка с другого устройства',
      updatedAt: date.add(const Duration(minutes: 1)),
    );

    await controller.replaceAllFromSync(
      [
        for (final existing in controller.state)
          if (existing.id == edited.id) edited else existing,
      ],
      baseline: List.of(controller.state),
    );

    expect(repository.replaceAllCount, 0);
    expect(repository.upsertedIds, [edited.id]);
    expect(repository.deletedIds, isEmpty);
    expect(
      repository.items.singleWhere((entry) => entry.id == edited.id).body,
      'Правка с другого устройства',
    );
  });

  test('one deletion from the cloud removes one record', () async {
    final (controller, repository) = await loaded();

    await controller.replaceAllFromSync(
      [
        for (final existing in controller.state)
          if (existing.id != 'record-7') existing,
      ],
      baseline: List.of(controller.state),
    );

    expect(repository.replaceAllCount, 0);
    expect(repository.upsertedIds, isEmpty);
    expect(repository.deletedIds, ['record-7']);
    expect(repository.items, hasLength(999));
  });

  test('a merge without changes writes nothing', () async {
    final (controller, repository) = await loaded();

    await controller.replaceAllFromSync(
      List.of(controller.state),
      baseline: List.of(controller.state),
    );

    expect(repository.replaceAllCount, 0);
    expect(repository.upsertedIds, isEmpty);
    expect(repository.deletedIds, isEmpty);
  });

  test('a record changed without a new time is still written', () async {
    // Ремонт данных прошлых версий может поправить запись, не трогая
    // updatedAt; сравнение только по времени потеряло бы такую правку.
    final (controller, repository) = await loaded();
    final repaired = item(3, body: 'Исправлено ремонтом');

    await controller.replaceAll([
      for (final existing in controller.state)
        if (existing.id == repaired.id) repaired else existing,
    ]);

    expect(repository.replaceAllCount, 0);
    expect(repository.upsertedIds, [repaired.id]);
  });
}
