import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';

import '../security/encrypted_json_store.dart';
import '../security/secure_entity_backend.dart';
import '../security/secure_entity_codec.dart';
import 'tool_data_repository.dart';

class EncryptedToolDataRepository implements ToolDataRepository {
  const EncryptedToolDataRepository({
    required this.store,
    this.plainRepository,
    this.backend,
  });

  static const storageKey = 'encrypted_tool_data_v1';
  static const entityKind = 'tool_data';
  static const _snapshotId = 'snapshot';

  final EncryptedJsonStore store;
  final ToolDataRepository? plainRepository;
  final SecureEntityBackend? backend;

  @override
  Future<ToolDataSnapshot> load() async {
    if (backend case final secureBackend?) {
      var rows = await secureBackend.loadSecureEntities(entityKind);
      if (rows.isEmpty) {
        final snapshot = await _loadLegacyOrPlain();
        await replaceAll(snapshot);
        rows = await secureBackend.loadSecureEntities(entityKind);
        final verified = await _decodeRows(rows);
        if (!_same(snapshot, verified)) {
          throw StateError('Encrypted tool data migration verification failed');
        }
        await store.remove(storageKey);
        await plainRepository?.replaceAll(const ToolDataSnapshot());
        return verified;
      }
      return _decodeRows(rows);
    }
    if (!await store.contains(storageKey)) {
      final snapshot =
          await plainRepository?.load() ?? const ToolDataSnapshot();
      await replaceAll(snapshot);
      await plainRepository?.replaceAll(const ToolDataSnapshot());
      return snapshot;
    }
    return ToolDataSnapshot.fromJson(await store.readMap(storageKey));
  }

  @override
  Future<void> replaceAll(ToolDataSnapshot snapshot) async {
    if (backend case final secureBackend?) {
      final record = await SecureEntityCodec(store.cipher).encode(
        _snapshotId,
        snapshot.toJson(),
      );
      await secureBackend.replaceSecureEntities(entityKind, [record]);
      return;
    }
    await store.writeMap(storageKey, snapshot.toJson());
  }

  Future<ToolDataSnapshot> _loadLegacyOrPlain() async {
    if (await store.contains(storageKey)) {
      return ToolDataSnapshot.fromJson(await store.readMap(storageKey));
    }
    return plainRepository?.load() ?? Future.value(const ToolDataSnapshot());
  }

  Future<ToolDataSnapshot> _decodeRows(List<SecureEntityRecord> rows) async {
    if (rows.length != 1) {
      throw const FormatException('Invalid encrypted tool data snapshot');
    }
    return ToolDataSnapshot.fromJson(
      await SecureEntityCodec(store.cipher).decode(rows.single),
    );
  }

  bool _same(ToolDataSnapshot first, ToolDataSnapshot second) =>
      _canonical(first) == _canonical(second);

  String _canonical(ToolDataSnapshot snapshot) => jsonEncode(snapshot.toJson());
}
