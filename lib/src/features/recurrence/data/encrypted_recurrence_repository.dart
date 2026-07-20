import '../../security/data/encrypted_json_store.dart';
import '../../security/data/secure_entity_backend.dart';
import '../../security/data/secure_entity_codec.dart';
import '../domain/recurrence_series.dart';
import 'recurrence_repository.dart';

class EncryptedRecurrenceRepository implements RecurrenceRepository {
  const EncryptedRecurrenceRepository({
    required this.store,
    required this.plainRepository,
    this.backend,
  });

  static const storageKey = 'encrypted_recurrence_series_v1';
  static const entityKind = 'recurrence_series';

  final EncryptedJsonStore store;
  final RecurrenceRepository plainRepository;
  final SecureEntityBackend? backend;

  SecureEntityCodec get _codec => SecureEntityCodec(store.cipher);

  @override
  Future<List<RecurrenceSeries>> loadAll() async {
    final secureBackend = backend;
    if (secureBackend != null) {
      var rows = await secureBackend.loadSecureEntities(entityKind);
      if (rows.isEmpty) {
        final plain = await plainRepository.loadAll();
        if (plain.isNotEmpty) {
          await replaceAll(plain);
          await plainRepository.replaceAll(const []);
          rows = await secureBackend.loadSecureEntities(entityKind);
        }
      }
      final result = <RecurrenceSeries>[];
      for (final row in rows) {
        result.add(RecurrenceSeries.fromJson(await _codec.decode(row)));
      }
      return result;
    }
    if (await store.contains(storageKey)) {
      return (await store.readList(storageKey)).map((entry) {
        return RecurrenceSeries.fromJson(
          Map<String, Object?>.from(entry as Map),
        );
      }).toList();
    }
    final plain = await plainRepository.loadAll();
    await replaceAll(plain);
    await plainRepository.replaceAll(const []);
    return plain;
  }

  @override
  Future<void> upsert(RecurrenceSeries series) async {
    if (backend != null) {
      final record = await _codec.encode(series.id, series.toJson());
      await backend!.upsertSecureEntity(
        kind: entityKind,
        rowKey: record.rowKey,
        lookupKey: record.lookupKey,
        encryptedPayload: record.encryptedPayload,
      );
      return;
    }
    final all = await loadAll();
    await replaceAll([
      for (final item in all)
        if (item.id == series.id) series else item,
      if (!all.any((item) => item.id == series.id)) series,
    ]);
  }

  @override
  Future<void> upsertAll(List<RecurrenceSeries> series) async {
    if (series.isEmpty) return;
    final secureBackend = backend;
    if (secureBackend != null) {
      final records = await Future.wait([
        for (final item in series) _codec.encode(item.id, item.toJson()),
      ]);
      await secureBackend.upsertSecureEntities(entityKind, records);
      return;
    }
    final byId = {
      for (final item in await loadAll()) item.id: item,
      for (final item in series) item.id: item,
    };
    await replaceAll(byId.values.toList());
  }

  @override
  Future<void> delete(String id) async {
    if (backend != null) {
      await backend!.deleteSecureEntity(entityKind, await _codec.lookupKey(id));
      return;
    }
    await replaceAll([
      for (final item in await loadAll())
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> replaceAll(List<RecurrenceSeries> series) async {
    if (backend != null) {
      final records = <SecureEntityRecord>[];
      for (final item in series) {
        records.add(await _codec.encode(item.id, item.toJson()));
      }
      await backend!.replaceSecureEntities(entityKind, records);
      return;
    }
    await store.writeList(
      storageKey,
      series.map((item) => item.toJson()).toList(),
    );
  }

  @override
  Future<void> close() async {}
}
