import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database/app_database.dart';
import '../../security/data/secure_entity_backend.dart';
import '../domain/memory_item.dart' as domain;
import '../domain/memory_status.dart';
import '../domain/memory_type.dart';
import 'memory_repository.dart';

class SqliteMemoryRepository implements MemoryRepository, SecureEntityBackend {
  SqliteMemoryRepository({
    AppDatabase? database,
    SharedPreferences? legacyPreferences,
    bool closeDatabase = true,
  })  : _database = database ?? AppDatabase(),
        _legacyPreferences = legacyPreferences,
        _closeDatabase = closeDatabase;

  static const legacyStorageKey = 'memory_items_v1';
  static const legacyMigrationKey = 'memory_items_sqlite_migrated_v1';

  final AppDatabase _database;
  final SharedPreferences? _legacyPreferences;
  final bool _closeDatabase;

  @override
  Future<List<SecureEntityRecord>> loadSecureEntities(String kind) async {
    final rows = await (_database.select(_database.secureEntities)
          ..where((row) => row.kind.equals(kind)))
        .get();
    return [
      for (final row in rows)
        SecureEntityRecord(
          rowKey: row.rowKey,
          lookupKey: row.lookupKey,
          encryptedPayload: row.encryptedPayload,
        ),
    ];
  }

  @override
  Future<void> upsertSecureEntity({
    required String kind,
    required String rowKey,
    required String lookupKey,
    required String encryptedPayload,
  }) async {
    await _database.transaction(() async {
      await (_database.delete(_database.secureEntities)
            ..where(
              (row) => row.kind.equals(kind) & row.lookupKey.equals(lookupKey),
            ))
          .go();
      await _database.into(_database.secureEntities).insert(
            SecureEntitiesCompanion.insert(
              kind: kind,
              rowKey: rowKey,
              lookupKey: lookupKey,
              encryptedPayload: encryptedPayload,
            ),
          );
    });
  }

  @override
  Future<void> upsertSecureEntities(
    String kind,
    List<SecureEntityRecord> records,
  ) async {
    if (records.isEmpty) return;
    await _database.transaction(() async {
      final lookupKeys = [for (final record in records) record.lookupKey];
      await (_database.delete(_database.secureEntities)
            ..where(
              (row) => row.kind.equals(kind) & row.lookupKey.isIn(lookupKeys),
            ))
          .go();
      await _database.batch((batch) {
        batch.insertAll(
          _database.secureEntities,
          [
            for (final record in records)
              SecureEntitiesCompanion.insert(
                kind: kind,
                rowKey: record.rowKey,
                lookupKey: record.lookupKey,
                encryptedPayload: record.encryptedPayload,
              ),
          ],
        );
      });
    });
  }

  @override
  Future<void> deleteSecureEntity(String kind, String lookupKey) async {
    await (_database.delete(_database.secureEntities)
          ..where(
            (row) => row.kind.equals(kind) & row.lookupKey.equals(lookupKey),
          ))
        .go();
  }

  @override
  Future<void> replaceSecureEntities(
    String kind,
    List<SecureEntityRecord> records,
  ) async {
    await _database.transaction(() async {
      await (_database.delete(_database.secureEntities)
            ..where((row) => row.kind.equals(kind)))
          .go();
      if (records.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.secureEntities,
            [
              for (final record in records)
                SecureEntitiesCompanion.insert(
                  kind: kind,
                  rowKey: record.rowKey,
                  lookupKey: record.lookupKey,
                  encryptedPayload: record.encryptedPayload,
                ),
            ],
          );
        });
      }
    });
  }

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
  Future<void> upsertAll(List<domain.MemoryItem> items) async {
    await _migrateLegacyItemsIfNeeded();
    final userItems = [
      for (final item in items)
        if (!_isStarterId(item.id)) item,
    ];
    if (userItems.isEmpty) return;
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.memoryItems,
        userItems.map(_toCompanion).toList(),
      );
    });
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
  Future<void> close() =>
      _closeDatabase ? _database.close() : Future<void>.value();

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
      seriesId: Value(item.seriesId),
      amountMinor: Value(item.amountMinor),
      paymentCategory: Value(item.paymentCategory),
      birthYear: Value(item.birthYear),
      isGeneratedOccurrence: Value(item.isGeneratedOccurrence),
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
      seriesId: row.seriesId,
      amountMinor: row.amountMinor,
      paymentCategory: row.paymentCategory,
      birthYear: row.birthYear,
      isGeneratedOccurrence: row.isGeneratedOccurrence,
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
