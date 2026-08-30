import 'package:drift/native.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_data/ez_data_io.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('enabling and disabling PIN migrates and verifies finance entries',
      () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final storage = _TestStorage(database);
    addTearDown(storage.close);
    final date = DateTime.utc(2026, 8, 30);
    await storage.financeRepository.replaceAll([
      FinanceEntry(
        id: 'income',
        kind: FinanceEntryKind.income,
        amount: '999.99',
        currencyCode: 'RUB',
        category: 'Подарок',
        occurredOn: date,
        createdAt: date,
        updatedAt: date,
      ),
    ]);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 7),
    );
    addTearDown(cipher.destroy);
    final service = SecurityDataMigrationService(storage);

    await service.encryptPlainData(
      cipher: cipher,
      snapshot: const SecurityDataMigrationSnapshot(),
    );

    expect(await storage.financeRepository.loadAll(), isEmpty);
    expect(
      await storage.secureEntityBackend.loadSecureEntities(
        EncryptedFinanceRepository.entityKind,
      ),
      hasLength(1),
    );

    await service.decryptToPlainData(cipher);

    final restored = await storage.financeRepository.loadAll();
    expect(restored.single.id, 'income');
    expect(restored.single.amount, '999.99');
    expect(
      await storage.secureEntityBackend.loadSecureEntities(
        EncryptedFinanceRepository.entityKind,
      ),
      isEmpty,
    );
  });
}

class _TestStorage implements LocalStorageScope {
  _TestStorage(this.database) {
    memoryRepository = SqliteMemoryRepository(
      database: database,
      closeDatabase: false,
    );
    recurrenceRepository = SqliteRecurrenceRepository(database, false);
    recurrenceExceptionRepository =
        SqliteRecurrenceExceptionRepository(database, false);
    financeRepository = SqliteFinanceRepository(database, false);
    secureEntityBackend = DriftSecureEntityBackend(database);
  }

  final AppDatabase database;

  @override
  late final MemoryRepository memoryRepository;

  @override
  late final RecurrenceRepository recurrenceRepository;

  @override
  late final RecurrenceExceptionRepository recurrenceExceptionRepository;

  @override
  late final FinanceRepository financeRepository;

  @override
  late final SecureEntityBackend secureEntityBackend;

  @override
  Future<void> close() => database.close();
}
