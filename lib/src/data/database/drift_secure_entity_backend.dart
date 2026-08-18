import 'package:drift/drift.dart';

import '../../features/security/data/secure_entity_backend.dart';
import 'app_database.dart';

class DriftSecureEntityBackend implements SecureEntityBackend {
  const DriftSecureEntityBackend(this._database);

  final AppDatabase _database;

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
      if (records.isEmpty) return;
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
}
