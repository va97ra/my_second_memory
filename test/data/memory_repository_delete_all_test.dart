import 'package:drift/native.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_data/ez_data_io.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Удаление пачкой убирает ровно названные записи — и в открытой базе, и в
/// зашифрованной.
void main() {
  final date = DateTime(2026, 11, 12, 9);

  MemoryItem item(String id) => MemoryItem(
        id: id,
        type: MemoryType.note,
        title: id,
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sqlite removes exactly the named records', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = SqliteMemoryRepository(
      database: database,
      closeDatabase: false,
    );
    await repository.replaceAll([item('a'), item('b'), item('c')]);

    await repository.deleteAll(['a', 'c', 'missing']);

    expect((await repository.loadAll()).map((entry) => entry.id), ['b']);
  });

  test('encrypted rows are removed by their lookup keys', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 6),
    );
    addTearDown(cipher.destroy);
    final repository = EncryptedMemoryRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: SqliteMemoryRepository(
        database: database,
        closeDatabase: false,
      ),
      backend: DriftSecureEntityBackend(database),
    );
    await repository.upsertAll([item('a'), item('b'), item('c')]);

    await repository.deleteAll(['a', 'c']);

    expect((await repository.loadAll()).map((entry) => entry.id), ['b']);
  });
}
