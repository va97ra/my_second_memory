import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'google_mark.dart';
import 'sync_card.dart';
import 'sync_error_text.dart';

/// Вход в облако.
///
/// Вход один — через Google. Пароля здесь нет и быть не должно: доступ к
/// облаку даёт Google, а данные шифрует отдельный пароль хранилища, который
/// спрашивают следующим шагом.
class SyncAccountForm extends StatelessWidget {
  const SyncAccountForm({
    super.key,
    required this.busy,
    required this.errorText,
    required this.onGoogle,
  });

  final bool busy;
  final String? errorText;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SyncCard(
      icon: Icons.cloud_sync_rounded,
      title: strings.syncSignIn,
      children: [
        Text(strings.synchronizationSubtitle),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const ValueKey('sync_google_sign_in'),
            onPressed: busy ? null : onGoogle,
            icon: const GoogleMark(),
            label: Text(strings.syncContinueWithGoogle),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 16),
          SyncErrorText(errorText!),
        ],
      ],
    );
  }
}
