/// Что не так с тем, что набрали на экране синхронизации.
///
/// Правила отделены от экрана, потому что от них зависит, уйдёт ли пароль в
/// облако: проверять их запуском экрана — плохая идея.
enum SyncFormProblem {
  /// Не похоже на email или пароль короче шести знаков.
  badCredentials,

  /// Пароль хранилища короче восьми знаков.
  shortVaultPassword,

  /// Пароль и его повтор разошлись.
  vaultMismatch,

  /// Код восстановления не набран.
  emptyRecoveryCode,
}

SyncFormProblem? validateSyncAccount({
  required String email,
  required String password,
}) {
  if (!email.contains('@') || password.length < 6) {
    return SyncFormProblem.badCredentials;
  }
  return null;
}

SyncFormProblem? validateSyncVault({
  required String password,
  required String confirmation,
  required bool vaultExists,
  required bool recoveryMode,
}) {
  if (recoveryMode) {
    return password.trim().isEmpty ? SyncFormProblem.emptyRecoveryCode : null;
  }
  if (password.length < 8) return SyncFormProblem.shortVaultPassword;
  // Новое хранилище набирают дважды: восстановить забытый пароль нечем.
  if (!vaultExists && password != confirmation) {
    return SyncFormProblem.vaultMismatch;
  }
  return null;
}
