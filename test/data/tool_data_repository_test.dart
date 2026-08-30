import 'package:drift/native.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_data/ez_data_io.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final date = DateTime.utc(2026, 8, 30, 12);
  final snapshot = ToolDataSnapshot(
    calculations: [
      SavedToolCalculation(
        id: 'conversion-1',
        name: 'Рабочий расход',
        payload: const SavedConversionPayload(
          category: 'flow',
          fromUnit: 'm3_h',
          toUnit: 'l_s',
          value: 3.6,
        ),
        createdAt: date,
        updatedAt: date,
      ),
    ],
    bookmarks: [
      ReferenceBookmark(
        entryId: 'ip_code',
        note: 'Проверить паспорт шкафа',
        updatedAt: date,
      ),
    ],
  );

  test('SQLite saves, changes and deletes tool entities', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = SqliteToolDataRepository(database, false);

    await repository.replaceAll(snapshot);
    final restored = await repository.load();
    expect(restored.calculations.single.name, 'Рабочий расход');
    expect(restored.bookmarks.single.note, 'Проверить паспорт шкафа');

    await repository.replaceAll(const ToolDataSnapshot());
    final deleted = await repository.load();
    expect(deleted.calculations, isEmpty);
    expect(deleted.bookmarks, isEmpty);
  });

  test('Web fallback round-trips typed tool data', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalToolDataRepository(preferences: preferences);

    await repository.replaceAll(snapshot);
    final restored = await repository.load();

    expect(restored.calculations.single.payload, isA<SavedConversionPayload>());
    expect(restored.bookmarks.single.entryId, 'ip_code');
  });

  test('encrypted fallback removes plaintext after migration', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final plain = LocalToolDataRepository(preferences: preferences);
    await plain.replaceAll(snapshot);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 4),
    );
    addTearDown(cipher.destroy);
    final encrypted = EncryptedToolDataRepository(
      store: EncryptedJsonStore(cipher: cipher, preferences: preferences),
      plainRepository: plain,
    );

    final restored = await encrypted.load();

    expect(restored.calculations.single.id, 'conversion-1');
    expect((await plain.load()).calculations, isEmpty);
    final stored =
        preferences.getString(EncryptedToolDataRepository.storageKey)!;
    expect(stored, isNot(contains('Рабочий расход')));
  });
}
