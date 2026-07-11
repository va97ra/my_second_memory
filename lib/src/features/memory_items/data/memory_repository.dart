import '../domain/memory_item.dart';

abstract interface class MemoryRepository {
  Future<List<MemoryItem>> loadAll();

  Future<void> upsert(MemoryItem item);

  Future<void> delete(String id);

  Future<void> replaceAll(List<MemoryItem> items);

  Future<void> close();
}
