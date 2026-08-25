import 'package:ez_core/ez_core.dart';

import '../state/sync_form_rules.dart';

/// Что показать над кнопкой: своя ошибка формы важнее облачной, потому что
/// человек только что её вызвал.
String? syncErrorText(
  AppStrings strings, {
  required SyncFormProblem? problem,
  required String? syncError,
}) {
  if (problem != null) return _problemText(strings, problem);
  return syncError == null ? null : strings.syncErrorMessage(syncError);
}

String _problemText(AppStrings strings, SyncFormProblem problem) {
  return switch (problem) {
    SyncFormProblem.shortVaultPassword => strings.isRu
        ? 'Используйте не менее 8 символов.'
        : 'Use at least 8 characters.',
    SyncFormProblem.vaultMismatch => strings.backupPasswordsDoNotMatch,
    SyncFormProblem.emptyRecoveryCode => strings.syncRecoveryCode,
  };
}
