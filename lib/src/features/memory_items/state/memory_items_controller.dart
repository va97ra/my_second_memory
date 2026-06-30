import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_memory_repository.dart';
import '../data/memory_repository.dart';
import '../domain/memory_item.dart';
import '../domain/memory_status.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>(
  (ref) => const LocalMemoryRepository(),
);

final memoryItemsControllerProvider =
    StateNotifierProvider<MemoryItemsController, List<MemoryItem>>((ref) {
  return MemoryItemsController(ref.watch(memoryRepositoryProvider));
});

class MemoryItemsController extends StateNotifier<List<MemoryItem>> {
  MemoryItemsController(this._repository) : super(const []) {
    load();
  }

  final MemoryRepository _repository;

  Future<void> load() async {
    final items = await _repository.loadItems();
    state = _sort(items);
  }

  Future<void> add(MemoryItem item) async {
    state = _sort([...state, item]);
    await _repository.saveItems(state);
  }

  Future<void> update(MemoryItem item) async {
    state = _sort([
      for (final existing in state)
        if (existing.id == item.id) item else existing,
    ]);
    await _repository.saveItems(state);
  }

  Future<void> archive(String id) async {
    final now = DateTime.now();
    state = _sort([
      for (final item in state)
        if (item.id == id)
          item.copyWith(status: MemoryStatus.archived, updatedAt: now)
        else
          item,
    ]);
    await _repository.saveItems(state);
  }

  Future<void> delete(String id) async {
    state = [
      for (final item in state)
        if (item.id != id) item,
    ];
    await _repository.saveItems(state);
  }

  List<MemoryItem> _sort(List<MemoryItem> items) {
    return [...items]..sort((a, b) {
        final byDate = a.memoryDate.compareTo(b.memoryDate);
        if (byDate != 0) {
          return byDate;
        }
        return b.priority.compareTo(a.priority);
      });
  }
}
