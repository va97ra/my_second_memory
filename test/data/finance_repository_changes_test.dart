import 'package:drift/native.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_data/ez_data_io.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Запись и удаление отдельных операций журнала — в открытой базе и в
/// зашифрованной — меняют только названное.
void main() {
  final date = DateTime(2026, 11, 12, 9);

  FinanceEntry entry(String id, {String amount = '100'}) => FinanceEntry(
        id: id,
        kind: FinanceEntryKind.expense,
        amount: amount,
        currencyCode: 'RUB',
        category: 'Продукты',
        occurredOn: date,
        createdAt: date,
        updatedAt: date,
      );

  Future<void> exercise(FinanceRepository repository) async {
    await repository.replaceAll([entry('a'), entry('b'), entry('c')]);

    await repository.upsertAll([entry('b', amount: '250'), entry('d')]);
    await repository.deleteAll(['a', 'missing']);

    final stored = {
      for (final value in await repository.loadAll()) value.id: value.amount,
    };
    expect(stored, {'b': '250', 'c': '100', 'd': '100'});
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sqlite changes only the named operations', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await exercise(SqliteFinanceRepository(database, false));
  });

  test('encrypted rows change only for the named operations', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 2),
    );
    addTearDown(cipher.destroy);

    await exercise(EncryptedFinanceRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: SqliteFinanceRepository(database, false),
      backend: DriftSecureEntityBackend(database),
    ));
  });

  test('the web journal changes only the named operations', () async {
    await exercise(const LocalFinanceRepository());
  });
}
