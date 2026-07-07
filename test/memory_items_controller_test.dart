import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_status.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';

class _MemoryRepository implements MemoryRepository {
  _MemoryRepository(this.items);

  List<MemoryItem> items;

  @override
  Future<List<MemoryItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<MemoryItem> items) async {
    this.items = items;
  }
}

void main() {
  test('delete removes item from state and repository', () async {
    final date = DateTime(2026, 6, 30);
    final repository = _MemoryRepository([
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
    final repository = _MemoryRepository([
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
    final repository = _MemoryRepository([
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
}
