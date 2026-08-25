
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';

import '../../support/memory_items_test_support.dart';

void main() {
  test('addAll persists generated records in one batch', () async {
    final date = DateTime(2026, 6, 30);
    final repository = FakeMemoryRepository(const []);
    final controller = MemoryItemsController(repository);
    final items = [
      for (var index = 0; index < 20; index++)
        MemoryItem(
          id: 'generated-$index',
          type: MemoryType.note,
          title: 'Generated $index',
          memoryDate: DateTime(date.year, date.month + index),
          createdAt: date,
          updatedAt: date,
        ),
    ];

    await controller.load();
    await controller.addAll(items);

    expect(repository.upsertAllCount, 1);
    expect(repository.items, hasLength(20));
    expect(controller.state, hasLength(20));
  });

  test('update persists only the changed record', () async {
    final date = DateTime(2026, 6, 30);
    final item = MemoryItem(
      id: 'one',
      type: MemoryType.note,
      title: 'One',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );
    final repository = FakeMemoryRepository([item]);
    final controller = MemoryItemsController(repository);

    await controller.load();
    await controller.update(item.copyWith(body: 'Changed'));

    expect(repository.upsertedIds, ['one']);
    expect(repository.replaceAllCount, 0);
  });

  test('concurrent updates are written in order and newest edit wins',
      () async {
    final date = DateTime(2026, 6, 30);
    final item = MemoryItem(
      id: 'ordered',
      type: MemoryType.note,
      title: 'Ordered',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );
    final repository = DelayedMemoryRepository([item]);
    final controller = MemoryItemsController(repository);

    await controller.load();
    final first = controller.update(item.copyWith(body: 'First'));
    await repository.firstWriteStarted.future;
    final second = controller.update(item.copyWith(body: 'Second'));
    repository.releaseFirstWrite.complete();
    await Future.wait([first, second]);

    expect(repository.writtenBodies, ['First', 'Second']);
    expect(repository.items.single.body, 'Second');
  });

  test('media is removed only after it is no longer referenced', () async {
    final date = DateTime(2026, 6, 30);
    MemoryItem item(String id) => MemoryItem(
          id: id,
          type: MemoryType.note,
          title: id,
          memoryDate: date,
          createdAt: date,
          updatedAt: date,
          imagePaths: const ['/app/image_shared.jpg'],
        );
    final repository = FakeMemoryRepository([item('first'), item('second')]);
    final mediaStorage = TrackingMediaStorage();
    final controller = MemoryItemsController(repository, null, mediaStorage);

    await controller.load();
    await controller.delete('first');
    expect(mediaStorage.deleted, isEmpty);

    await controller.delete('second');
    expect(mediaStorage.deleted, ['/app/image_shared.jpg']);
  });

  test('delete removes item from state and repository', () async {
    final date = DateTime(2026, 6, 30);
    final repository = FakeMemoryRepository([
      MemoryItem(
        id: 'keep',
        type: MemoryType.note,
        title: 'Keep',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
      MemoryItem(
        id: 'delete',
        type: MemoryType.note,
        title: 'Delete',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
    ]);
    final controller = MemoryItemsController(repository);

    await controller.load();
    await controller.delete('delete');

    expect(controller.state.map((item) => item.id), ['keep']);
    expect(repository.items.map((item) => item.id), ['keep']);
  });

  test('toggleDone switches active and done states', () async {
    final date = DateTime(2026, 6, 30);
    final repository = FakeMemoryRepository([
      MemoryItem(
        id: 'toggle',
        type: MemoryType.note,
        title: 'Toggle',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      ),
    ]);
    final controller = MemoryItemsController(repository);

    await controller.load();
    await controller.toggleDone('toggle');

    expect(controller.state.single.status, MemoryStatus.done);
    expect(repository.items.single.status, MemoryStatus.done);

    await controller.toggleDone('toggle');

    expect(controller.state.single.status, MemoryStatus.active);
    expect(repository.items.single.status, MemoryStatus.active);
  });

  test('restore returns archived item to active state', () async {
    final date = DateTime(2026, 6, 30);
    final repository = FakeMemoryRepository([
      MemoryItem(
        id: 'archived',
        type: MemoryType.note,
        title: 'Archived',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
        status: MemoryStatus.archived,
      ),
    ]);
    final controller = MemoryItemsController(repository);

    await controller.load();
    await controller.restore('archived');

    expect(controller.state.single.status, MemoryStatus.active);
    expect(repository.items.single.status, MemoryStatus.active);
  });

  test('sync replacement preserves in-flight local changes and deletions',
      () async {
    final baselineTime = DateTime.utc(2026, 8, 22, 12);
    MemoryItem item(
      String id,
      String title, {
      DateTime? updatedAt,
    }) =>
        MemoryItem(
          id: id,
          type: MemoryType.note,
          title: title,
          memoryDate: baselineTime,
          createdAt: baselineTime,
          updatedAt: updatedAt ?? baselineTime,
        );

    final repository = FakeMemoryRepository([
      item('edited', 'Before local edit'),
      item('deleted', 'Delete while syncing'),
      item('remote-edit', 'Before remote edit'),
    ]);
    final controller = MemoryItemsController(repository);
    await controller.load();
    final baseline = [...controller.state];

    final localTime = baselineTime.add(const Duration(minutes: 2));
    await controller.update(
      item('edited', 'Local edit', updatedAt: localTime),
    );
    await controller.add(
      item('local-addition', 'Added locally', updatedAt: localTime),
    );
    await controller.delete('deleted');

    final remoteTime = baselineTime.add(const Duration(minutes: 1));
    await controller.replaceAllFromSync(
      [
        item('edited', 'Stale cloud edit', updatedAt: remoteTime),
        item('deleted', 'Stale cloud copy', updatedAt: remoteTime),
        item('remote-edit', 'Cloud edit', updatedAt: remoteTime),
        item('remote-addition', 'Added in cloud', updatedAt: remoteTime),
      ],
      baseline: baseline,
    );

    final byId = {for (final value in controller.state) value.id: value};
    expect(
      byId.keys,
      unorderedEquals([
        'edited',
        'local-addition',
        'remote-edit',
        'remote-addition',
      ]),
    );
    expect(byId['edited']!.title, 'Local edit');
    expect(byId['local-addition']!.title, 'Added locally');
    expect(byId['remote-edit']!.title, 'Cloud edit');
    expect(byId, isNot(contains('deleted')));
    expect(
      repository.items.map((value) => value.id),
      unorderedEquals(byId.keys),
    );
  });
}
