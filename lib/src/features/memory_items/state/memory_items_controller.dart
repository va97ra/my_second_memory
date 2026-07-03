import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/memory_repository.dart';
import '../data/memory_repository_factory.dart';
import '../domain/memory_item.dart';
import '../domain/memory_status.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>(
  (ref) => createMemoryRepository(),
);

final memoryItemsControllerProvider =
    StateNotifierProvider<MemoryItemsController, List<MemoryItem>>((ref) {
  return MemoryItemsController(ref.watch(memoryRepositoryProvider));
});

class MemoryItemsController extends StateNotifier<List<MemoryItem>> {
  MemoryItemsController(this._repository) : super(const []) {
    _loadFuture = _load();
  }

  final MemoryRepository _repository;
  late final Future<void> _loadFuture;

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    final items = await _repository.loadItems();
    state = _sort(items);
  }

  Future<void> add(MemoryItem item) async {
    await _loadFuture;
    state = _sort([...state, item]);
    await _repository.saveItems(state);
  }

  Future<void> update(MemoryItem item) async {
    await _loadFuture;
    state = _sort([
      for (final existing in state)
        if (existing.id == item.id) item else existing,
    ]);
    await _repository.saveItems(state);
  }

  Future<void> archive(String id) async {
    await _loadFuture;
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

  Future<void> restore(String id) async {
    await _loadFuture;
    final now = DateTime.now();
    state = _sort([
      for (final item in state)
        if (item.id == id)
          item.copyWith(status: MemoryStatus.active, updatedAt: now)
        else
          item,
    ]);
    await _repository.saveItems(state);
  }

  Future<void> toggleDone(String id) async {
    await _loadFuture;
    final now = DateTime.now();
    state = _sort([
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            status: item.isDone ? MemoryStatus.active : MemoryStatus.done,
            updatedAt: now,
          )
        else
          item,
    ]);
    await _repository.saveItems(state);
  }

  Future<void> delete(String id) async {
    await _loadFuture;
    state = [
      for (final item in state)
        if (item.id != id) item,
    ];
    await _repository.saveItems(state);
  }

  Future<void> replaceAll(List<MemoryItem> items) async {
    await _loadFuture;
    state = _sort(items);
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
