import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../security/data/app_cipher.dart';
import '../domain/sync_models.dart';

class SyncKeyStore {
  SyncKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> save(String userId, AppCipher cipher) {
    return _storage.write(
      key: 'sync_master_key_$userId',
      value: base64Encode(cipher.exportKeyBytes()),
    );
  }

  Future<AppCipher?> read(String userId) async {
    final value = await _storage.read(key: 'sync_master_key_$userId');
    return value == null ? null : AppCipher.fromKeyBytes(base64Decode(value));
  }

  Future<void> delete(String userId) {
    return _storage.delete(key: 'sync_master_key_$userId');
  }
}

class SyncTombstoneStore {
  const SyncTombstoneStore();

  Future<Map<String, DateTime>> read(
    String userId, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(userId, kind));
    if (raw == null) return {};
    final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
    return {
      for (final entry in json.entries)
        entry.key: DateTime.parse(entry.value as String),
    };
  }

  Future<void> write(
    String userId,
    Map<String, DateTime> values, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(userId, kind),
      jsonEncode({
        for (final entry in values.entries)
          entry.key: entry.value.toUtc().toIso8601String(),
      }),
    );
  }

  Future<void> markDeleted(
    String userId,
    String id,
    DateTime deletedAt, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    final values = await read(userId, kind: kind);
    final previous = values[id];
    if (previous == null || deletedAt.isAfter(previous)) {
      values[id] = deletedAt;
      await write(userId, values, kind: kind);
    }
  }

  String _key(String userId, SyncEntityKind kind) {
    if (kind == SyncEntityKind.memoryItem) {
      return 'sync_memory_tombstones_$userId';
    }
    return 'sync_${kind.storageName}_tombstones_$userId';
  }
}
