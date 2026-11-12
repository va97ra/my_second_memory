import 'package:drift/native.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_data/ez_data_io.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/local_storage_test_support.dart';

void main() {
  test('enabling and disabling PIN migrates finance and tool data', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final storage = TestLocalStorage(database);
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
    await storage.toolDataRepository.replaceAll(ToolDataSnapshot(
      calculations: [
        SavedToolCalculation(
          id: 'conversion',
          name: 'Личная заметка',
          payload: const SavedConversionPayload(
            category: 'flow',
            fromUnit: 'm3_h',
            toUnit: 'l_s',
            value: 1,
          ),
          createdAt: date,
          updatedAt: date,
        ),
      ],
    ));
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
    expect((await storage.toolDataRepository.load()).calculations, isEmpty);
    expect(
      await storage.secureEntityBackend.loadSecureEntities(
        EncryptedToolDataRepository.entityKind,
      ),
      hasLength(1),
    );

    await service.decryptToPlainData(cipher);

    final restored = await storage.financeRepository.loadAll();
    expect(restored.single.id, 'income');
    expect(restored.single.amount, '999.99');
    expect(
      (await storage.toolDataRepository.load()).calculations.single.name,
      'Личная заметка',
    );
    expect(
      await storage.secureEntityBackend.loadSecureEntities(
        EncryptedFinanceRepository.entityKind,
      ),
      isEmpty,
    );
  });
}
