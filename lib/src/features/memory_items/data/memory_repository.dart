import '../domain/memory_item.dart';

abstract interface class MemoryRepository {
  Future<List<MemoryItem>> loadItems();

  Future<void> saveItems(List<MemoryItem> items);
}
