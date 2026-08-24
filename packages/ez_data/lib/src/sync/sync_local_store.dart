import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security/app_cipher.dart';
import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';

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

  static final Map<String, SequentialTaskQueue> _queues = {};

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
    await _queue(userId, kind).add(() async {
      final values = await read(userId, kind: kind);
      final previous = values[id];
      if (previous == null || deletedAt.isAfter(previous)) {
        values[id] = deletedAt;
        await write(userId, values, kind: kind);
      }
    });
  }

  /// Applies an engine snapshot without overwriting tombstones recorded while
  /// that engine was waiting on the network.
  Future<void> reconcile(
    String userId, {
    required Map<String, DateTime> baseline,
    required Map<String, DateTime> desired,
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) async {
    await _queue(userId, kind).add(() async {
      final current = await read(userId, kind: kind);
      var changed = false;

      for (final entry in baseline.entries) {
        if (desired.containsKey(entry.key)) continue;
        final latest = current[entry.key];
        if (latest != null && !latest.isAfter(entry.value)) {
          current.remove(entry.key);
          changed = true;
        }
      }

      for (final entry in desired.entries) {
        if (baseline[entry.key] == entry.value) continue;
        final latest = current[entry.key];
        if (latest == null || entry.value.isAfter(latest)) {
          current[entry.key] = entry.value;
          changed = true;
        }
      }

      if (changed) await write(userId, current, kind: kind);
    });
  }

  SequentialTaskQueue _queue(String userId, SyncEntityKind kind) =>
      _queues.putIfAbsent(_key(userId, kind), SequentialTaskQueue.new);

  String _key(String userId, SyncEntityKind kind) {
    if (kind == SyncEntityKind.memoryItem) {
      return 'sync_memory_tombstones_$userId';
    }
    return 'sync_${kind.storageName}_tombstones_$userId';
  }
}
