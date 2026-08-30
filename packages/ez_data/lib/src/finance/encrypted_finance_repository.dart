import 'package:ez_domain/ez_domain.dart';

import '../security/encrypted_json_store.dart';
import '../security/secure_entity_backend.dart';
import '../security/secure_entity_codec.dart';
import 'finance_repository.dart';

class EncryptedFinanceRepository implements FinanceRepository {
  const EncryptedFinanceRepository({
    required this.store,
    this.plainRepository,
    this.backend,
  });

  static const storageKey = 'encrypted_finance_entries_v1';
  static const entityKind = 'finance_entry';

  final EncryptedJsonStore store;
  final FinanceRepository? plainRepository;
  final SecureEntityBackend? backend;

  @override
  Future<List<FinanceEntry>> loadAll() async {
    if (backend case final secureBackend?) {
      var rows = await secureBackend.loadSecureEntities(entityKind);
      if (rows.isEmpty) {
        final entries = await _loadLegacyOrPlain();
        await _replaceRows(entries);
        rows = await secureBackend.loadSecureEntities(entityKind);
        final verified = await _decodeRows(rows);
        if (verified.length != entries.length) {
          throw StateError('Encrypted finance migration verification failed');
        }
        await store.remove(storageKey);
        await plainRepository?.replaceAll(const []);
        return verified;
      }
      return _decodeRows(rows);
    }
    if (!await store.contains(storageKey)) {
      final entries = await plainRepository?.loadAll() ?? const [];
      await replaceAll(entries);
      await plainRepository?.replaceAll(const []);
      return entries;
    }
    final decoded = await store.readList(storageKey);
    return [
      for (final item in decoded)
        FinanceEntry.fromJson(Map<String, Object?>.from(item as Map)),
    ];
  }

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {
    if (backend != null) return _replaceRows(entries);
    await store.writeList(
      storageKey,
      [for (final entry in entries) entry.toJson()],
    );
  }

  SecureEntityCodec get _codec => SecureEntityCodec(store.cipher);

  Future<List<FinanceEntry>> _loadLegacyOrPlain() async {
    if (await store.contains(storageKey)) {
      final decoded = await store.readList(storageKey);
      return [
        for (final item in decoded)
          FinanceEntry.fromJson(Map<String, Object?>.from(item as Map)),
      ];
    }
    return plainRepository?.loadAll() ?? Future.value(const []);
  }

  Future<List<FinanceEntry>> _decodeRows(List<SecureEntityRecord> rows) async {
    final entries = <FinanceEntry>[];
    for (final row in rows) {
      entries.add(FinanceEntry.fromJson(await _codec.decode(row)));
    }
    return entries;
  }

  Future<void> _replaceRows(List<FinanceEntry> entries) async {
    final records = <SecureEntityRecord>[];
    for (final entry in entries) {
      records.add(await _codec.encode(entry.id, entry.toJson()));
    }
    await backend!.replaceSecureEntities(entityKind, records);
  }
}
