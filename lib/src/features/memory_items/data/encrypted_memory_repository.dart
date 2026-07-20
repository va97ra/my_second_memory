import '../../security/data/encrypted_json_store.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../security/data/secure_entity_codec.dart';
import '../domain/memory_item.dart';
import 'memory_repository.dart';

class EncryptedMemoryRepository implements MemoryRepository {
  const EncryptedMemoryRepository({
    required this.store,
    required this.plainRepository,
  });

  static const storageKey = 'encrypted_memory_items_v1';
  static const entityKind = 'memory_item';

  final EncryptedJsonStore store;
  final MemoryRepository plainRepository;

  SecureEntityBackend? get _backend => plainRepository is SecureEntityBackend
      ? plainRepository as SecureEntityBackend
      : null;

  SecureEntityCodec get _codec => SecureEntityCodec(store.cipher);

  @override
  Future<List<MemoryItem>> loadAll() async {
    final backend = _backend;
    if (backend != null) {
      var rows = await backend.loadSecureEntities(entityKind);
      if (rows.isEmpty) {
        final legacyItems = await _loadLegacyOrPlain();
        await _replaceSecureRows(legacyItems);
        rows = await backend.loadSecureEntities(entityKind);
        final verified = await _decodeRows(rows);
        if (verified.length != legacyItems.length) {
          throw StateError('Encrypted memory migration verification failed');
        }
        await store.remove(storageKey);
        await plainRepository.replaceAll(const []);
        return verified;
      }
      return _decodeRows(rows);
    }

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
    final backend = _backend;
    if (backend != null) {
      final record = await _codec.encode(item.id, item.toJson());
      await backend.upsertSecureEntity(
        kind: entityKind,
        rowKey: record.rowKey,
        lookupKey: record.lookupKey,
        encryptedPayload: record.encryptedPayload,
      );
      return;
    }
    final items = await loadAll();
    await replaceAll([
      for (final existing in items)
        if (existing.id == item.id) item else existing,
      if (!items.any((existing) => existing.id == item.id)) item,
    ]);
  }

  @override
  Future<void> upsertAll(List<MemoryItem> items) async {
    if (items.isEmpty) return;
    final backend = _backend;
    if (backend != null) {
      final records = <SecureEntityRecord>[];
      for (var offset = 0; offset < items.length; offset += 32) {
        final end = offset + 32 < items.length ? offset + 32 : items.length;
        records.addAll(await Future.wait([
          for (final item in items.sublist(offset, end))
            _codec.encode(item.id, item.toJson()),
        ]));
        await Future<void>.delayed(Duration.zero);
      }
      await backend.upsertSecureEntities(entityKind, records);
      return;
    }
    final itemsById = {
      for (final item in await loadAll()) item.id: item,
      for (final item in items) item.id: item,
    };
    await replaceAll(itemsById.values.toList());
  }

  @override
  Future<void> delete(String id) async {
    final backend = _backend;
    if (backend != null) {
      await backend.deleteSecureEntity(entityKind, await _codec.lookupKey(id));
      return;
    }
    await replaceAll([
      for (final item in await loadAll())
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    if (_backend != null) {
      await _replaceSecureRows(items);
      return;
    }
    await store.writeList(
      storageKey,
      items.map((item) => item.toJson()).toList(),
    );
  }

  @override
  Future<void> close() async {}

  Future<List<MemoryItem>> _loadLegacyOrPlain() async {
    if (await store.contains(storageKey)) {
      final decoded = await store.readList(storageKey);
      return decoded.map((entry) {
        return MemoryItem.fromJson(Map<String, Object?>.from(entry as Map));
      }).toList();
    }
    return plainRepository.loadAll();
  }

  Future<List<MemoryItem>> _decodeRows(
    List<SecureEntityRecord> rows,
  ) async {
    final items = <MemoryItem>[];
    for (final row in rows) {
      items.add(MemoryItem.fromJson(await _codec.decode(row)));
    }
    return items;
  }

  Future<void> _replaceSecureRows(List<MemoryItem> items) async {
    final backend = _backend!;
    final records = <SecureEntityRecord>[];
    for (final item in items) {
      records.add(await _codec.encode(item.id, item.toJson()));
    }
    await backend.replaceSecureEntities(entityKind, records);
  }
}
