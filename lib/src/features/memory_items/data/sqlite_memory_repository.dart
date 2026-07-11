import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database/app_database.dart';
import '../domain/memory_item.dart' as domain;
import '../domain/memory_status.dart';
import '../domain/memory_type.dart';
import 'memory_repository.dart';

class SqliteMemoryRepository implements MemoryRepository {
  SqliteMemoryRepository({
    AppDatabase? database,
    SharedPreferences? legacyPreferences,
  })  : _database = database ?? AppDatabase(),
        _legacyPreferences = legacyPreferences;

  static const legacyStorageKey = 'memory_items_v1';
  static const legacyMigrationKey = 'memory_items_sqlite_migrated_v1';

  final AppDatabase _database;
  final SharedPreferences? _legacyPreferences;

  @override
  Future<List<domain.MemoryItem>> loadAll() async {
    await _migrateLegacyItemsIfNeeded();
    final rows = await _database.select(_database.memoryItems).get();
    final userRows = [
      for (final row in rows)
        if (!_isStarterId(row.id)) row,
    ];

    if (userRows.length != rows.length) {
      await _deleteStarterRows();
    }

    return userRows.map(_fromRow).toList();
  }

  @override
  Future<void> upsert(domain.MemoryItem item) async {
    await _migrateLegacyItemsIfNeeded();
    if (_isStarterId(item.id)) {
      return;
    }
    await _database
        .into(_database.memoryItems)
        .insertOnConflictUpdate(_toCompanion(item));
  }

  @override
  Future<void> delete(String id) async {
    await _migrateLegacyItemsIfNeeded();
    await (_database.delete(_database.memoryItems)
          ..where((row) => row.id.equals(id)))
        .go();
  }

  @override
  Future<void> replaceAll(List<domain.MemoryItem> items) async {
    await _migrateLegacyItemsIfNeeded();
    final userItems = [
      for (final item in items)
        if (!_isStarterId(item.id)) item,
    ];

    await _database.transaction(() async {
      if (userItems.isEmpty) {
        await _database.delete(_database.memoryItems).go();
      } else {
        final placeholders = List.filled(userItems.length, '?').join(', ');
        await _database.customStatement(
          'DELETE FROM memory_items WHERE id NOT IN ($placeholders)',
          userItems.map((item) => item.id).toList(),
        );
      }

      for (final item in userItems) {
        await _database
            .into(_database.memoryItems)
            .insertOnConflictUpdate(_toCompanion(item));
      }
    });
  }

  @override
  Future<void> close() => _database.close();

  Future<void> _migrateLegacyItemsIfNeeded() async {
    final prefs = _legacyPreferences ?? await SharedPreferences.getInstance();
    if (prefs.getBool(legacyMigrationKey) == true) {
      return;
    }

    final raw = prefs.getString(legacyStorageKey);
    if (raw == null || raw.isEmpty) {
      await prefs.setBool(legacyMigrationKey, true);
      return;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final legacyItems = decoded.map((entry) {
      return domain.MemoryItem.fromJson(
        Map<String, Object?>.from(entry as Map),
      );
    }).where((item) {
      return !_isStarterId(item.id);
    }).toList();

    await _database.transaction(() async {
      for (final item in legacyItems) {
        await _database
            .into(_database.memoryItems)
            .insertOnConflictUpdate(_toCompanion(item));
      }
      await _deleteStarterRows();
    });
    await prefs.setBool(legacyMigrationKey, true);
  }

  Future<void> _deleteStarterRows() async {
    await (_database.delete(_database.memoryItems)
          ..where((row) {
            return row.id.isIn([
              'starter-event',
              'starter-project',
              'starter-person',
            ]);
          }))
        .go();
  }

  MemoryItemsCompanion _toCompanion(domain.MemoryItem item) {
    return MemoryItemsCompanion(
      id: Value(item.id),
      type: Value(item.type.name),
      title: Value(item.title),
      body: Value(item.body),
      timeMinutes: Value(item.timeMinutes),
      memoryDate: Value(item.memoryDate),
      createdAt: Value(item.createdAt),
      updatedAt: Value(item.updatedAt),
      status: Value(item.status.name),
      priority: Value(item.priority),
      tagsJson: Value(jsonEncode(item.tags)),
      remindAt: Value(item.remindAt),
      reminderSoundUri: Value(item.reminderSoundUri),
      reminderSoundName: Value(item.reminderSoundName),
      repeatRule: Value(item.repeatRule),
      projectId: Value(item.projectId),
      personIdsJson: Value(jsonEncode(item.personIds)),
      placeId: Value(item.placeId),
      audioPath: Value(item.audioPath),
      audioDurationSeconds: Value(item.audioDurationSeconds),
      imagePathsJson: Value(jsonEncode(item.imagePaths)),
      transcript: Value(item.transcript),
    );
  }

  domain.MemoryItem _fromRow(MemoryItemRow row) {
    return domain.MemoryItem(
      id: row.id,
      type: MemoryType.values.byName(row.type),
      title: row.title,
      body: row.body,
      timeMinutes: row.timeMinutes,
      memoryDate: row.memoryDate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      status: MemoryStatus.values.byName(row.status),
      priority: row.priority,
      tags: _decodeStringList(row.tagsJson),
      remindAt: row.remindAt,
      reminderSoundUri: row.reminderSoundUri,
      reminderSoundName: row.reminderSoundName,
      repeatRule: row.repeatRule,
      projectId: row.projectId,
      personIds: _decodeStringList(row.personIdsJson),
      placeId: row.placeId,
      audioPath: row.audioPath,
      audioDurationSeconds: row.audioDurationSeconds,
      imagePaths: _decodeStringList(row.imagePathsJson),
      transcript: row.transcript,
    );
  }

  List<String> _decodeStringList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<String>();
  }

  bool _isStarterId(String id) {
    return id == 'starter-event' ||
        id == 'starter-project' ||
        id == 'starter-person';
  }
}
