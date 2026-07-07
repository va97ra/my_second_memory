import 'package:flutter_test/flutter_test.dart';
import 'package:my_second_memory/src/features/accounts/data/encrypted_account_repository.dart';
import 'package:my_second_memory/src/features/accounts/data/local_account_repository.dart';
import 'package:my_second_memory/src/features/accounts/domain/account_item.dart';
import 'package:my_second_memory/src/features/accounts/state/accounts_controller.dart';
import 'package:my_second_memory/src/features/security/data/app_cipher.dart';
import 'package:my_second_memory/src/features/security/data/encrypted_json_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('accounts can be created edited and deleted in encrypted storage',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 7),
    );
    final repository = EncryptedAccountRepository(
      store: EncryptedJsonStore(cipher: cipher),
    );
    final controller = AccountsController(repository);
    await Future<void>.delayed(Duration.zero);
    final now = DateTime(2026, 7, 7);

    await controller.add(
      AccountItem(
        id: 'acc',
        serviceName: 'Mail',
        login: 'user',
        password: 'secret',
        website: 'https://mail.test',
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(controller.state.single.password, 'secret');

    await controller.update(
      controller.state.single.copyWith(password: 'new-secret'),
    );
    expect(controller.state.single.password, 'new-secret');

    await controller.delete('acc');
    expect(controller.state, isEmpty);
  });

  test('wrong pin cannot decrypt account storage', () async {
    SharedPreferences.setMockInitialValues({});
    final salt = List<int>.filled(16, 9);
    final firstCipher = await AppCipher.fromPin(pin: '1234', salt: salt);
    final secondCipher = await AppCipher.fromPin(pin: '9999', salt: salt);
    final now = DateTime(2026, 7, 7);

    final firstRepository = EncryptedAccountRepository(
      store: EncryptedJsonStore(cipher: firstCipher),
    );
    await firstRepository.saveAccounts([
      AccountItem(
        id: 'acc',
        serviceName: 'Bank',
        login: 'user',
        password: 'secret',
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    final secondRepository = EncryptedAccountRepository(
      store: EncryptedJsonStore(cipher: secondCipher),
    );
    expect(secondRepository.loadAccounts, throwsA(isA<Exception>()));
  });

  test('encrypted account repository migrates plaintext accounts', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 7, 7);
    const plainRepository = LocalAccountRepository();
    await plainRepository.saveAccounts([
      AccountItem(
        id: 'acc',
        serviceName: 'Mail',
        login: 'user',
        password: 'secret',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    final cipher = await AppCipher.fromPin(
      pin: '1234',
      salt: List<int>.filled(16, 5),
    );
    final encryptedRepository = EncryptedAccountRepository(
      store: EncryptedJsonStore(cipher: cipher),
      plainRepository: plainRepository,
    );

    final accounts = await encryptedRepository.loadAccounts();

    expect(accounts.single.password, 'secret');
    expect(await plainRepository.loadAccounts(), isEmpty);
  });
}
