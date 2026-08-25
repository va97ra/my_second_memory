import 'package:ezhednevnik_v2/src/features/sync/state/sync_form_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Пароль хранилища', () {
    test('новое хранилище требует повтора пароля', () {
      expect(
        validateSyncVault(
          password: 'long-enough',
          confirmation: 'long-enough',
          vaultExists: false,
          recoveryMode: false,
        ),
        isNull,
      );
      expect(
        validateSyncVault(
          password: 'long-enough',
          confirmation: 'mistyped',
          vaultExists: false,
          recoveryMode: false,
        ),
        SyncFormProblem.vaultMismatch,
      );
    });

    test('у существующего хранилища повтор не спрашивают', () {
      expect(
        validateSyncVault(
          password: 'long-enough',
          confirmation: '',
          vaultExists: true,
          recoveryMode: false,
        ),
        isNull,
      );
    });

    test('короткий пароль не принимается', () {
      expect(
        validateSyncVault(
          password: '1234567',
          confirmation: '1234567',
          vaultExists: false,
          recoveryMode: false,
        ),
        SyncFormProblem.shortVaultPassword,
      );
    });

    test('код восстановления проверяется только на пустоту', () {
      expect(
        validateSyncVault(
          password: 'abc',
          confirmation: '',
          vaultExists: true,
          recoveryMode: true,
        ),
        isNull,
      );
      expect(
        validateSyncVault(
          password: '   ',
          confirmation: '',
          vaultExists: true,
          recoveryMode: true,
        ),
        SyncFormProblem.emptyRecoveryCode,
      );
    });
  });
}
