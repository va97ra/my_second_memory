import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vault password and recovery code unlock the same key', () async {
    const crypto = SyncVaultCrypto();
    final created = await crypto.create('correct horse battery staple');
    final passwordCipher = await crypto.unlock(
      created.profile,
      'correct horse battery staple',
    );
    final recoveryCipher = await crypto.unlockWithRecoveryCode(
      created.profile,
      created.recoveryCode,
    );
    addTearDown(created.cipher.destroy);
    addTearDown(passwordCipher.destroy);
    addTearDown(recoveryCipher.destroy);

    final encrypted = await created.cipher.encryptString('device A');
    expect(await passwordCipher.decryptString(encrypted), 'device A');
    expect(await recoveryCipher.decryptString(encrypted), 'device A');
  });

  test('wrong recovery code cannot unlock another vault', () async {
    const crypto = SyncVaultCrypto();
    final first = await crypto.create('first-password');
    final second = await crypto.create('second-password');
    addTearDown(first.cipher.destroy);
    addTearDown(second.cipher.destroy);

    await expectLater(
      crypto.unlockWithRecoveryCode(first.profile, second.recoveryCode),
      throwsFormatException,
    );
  });

  test('wrong synchronization password cannot unwrap the vault', () async {
    const crypto = SyncVaultCrypto();
    final created = await crypto.create('right-password');
    addTearDown(created.cipher.destroy);

    await expectLater(
      crypto.unlock(created.profile, 'wrong-password'),
      throwsFormatException,
    );
  });
}
