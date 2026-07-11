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
  Future<List<MemoryItem>> loadAll() async {
    if (await store.contains(storageKey)) {
      final decoded = await store.readList(storageKey);
      return decoded.map((entry) {
        return MemoryItem.fromJson(Map<String, Object?>.from(entry as Map));
      }).toList();
    }

    final items = await plainRepository.loadAll();
    await replaceAll(items);
    await plainRepository.replaceAll(const []);
    return items;
  }

  @override
  Future<void> upsert(MemoryItem item) async {
    final items = await loadAll();
    await replaceAll([
      for (final existing in items)
        if (existing.id == item.id) item else existing,
      if (!items.any((existing) => existing.id == item.id)) item,
    ]);
  }

  @override
  Future<void> delete(String id) async {
    await replaceAll([
      for (final item in await loadAll())
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    await store.writeList(
      storageKey,
      items.map((item) => item.toJson()).toList(),
    );
  }

  @override
  Future<void> close() async {}
}
