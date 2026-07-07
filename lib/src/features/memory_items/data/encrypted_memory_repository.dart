import '../../security/data/encrypted_json_store.dart';
import '../domain/memory_item.dart';
import 'memory_repository.dart';

class EncryptedMemoryRepository implements MemoryRepository {
  const EncryptedMemoryRepository({
    required this.store,
    required this.plainRepository,
  });

  static const storageKey = 'encrypted_memory_items_v1';

  final EncryptedJsonStore store;
  final MemoryRepository plainRepository;

  @override
  Future<List<MemoryItem>> loadItems() async {
    if (await store.contains(storageKey)) {
      final decoded = await store.readList(storageKey);
      return decoded.map((entry) {
        return MemoryItem.fromJson(Map<String, Object?>.from(entry as Map));
      }).toList();
    }

    final items = await plainRepository.loadItems();
    await saveItems(items);
    await plainRepository.saveItems(const []);
    return items;
  }

  @override
  Future<void> saveItems(List<MemoryItem> items) async {
    await store.writeList(
      storageKey,
      items.map((item) => item.toJson()).toList(),
    );
  }
}
