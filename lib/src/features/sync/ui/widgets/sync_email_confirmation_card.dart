import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'sync_card.dart';
import 'sync_error_text.dart';

/// Письмо с подтверждением отправлено: дальше ждут перехода по ссылке.
class SyncEmailConfirmationCard extends StatelessWidget {
  const SyncEmailConfirmationCard({
    super.key,
    required this.email,
    required this.resending,
    required this.resent,
    required this.errorText,
    required this.onResend,
    required this.onBackToSignIn,
  });

  final String? email;
  final bool resending;
  final bool resent;
  final String? errorText;
  final VoidCallback onResend;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SyncCard(
      icon: Icons.mark_email_unread_rounded,
      title: strings.syncCheckEmail,
      children: [
        if (email != null) SelectableText(email!),
        const SizedBox(height: 12),
        Text(strings.syncCheckEmailHint),
        if (resent) ...[
          const SizedBox(height: 12),
          Text(
            strings.syncEmailResent,
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 12),
          SyncErrorText(errorText!),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: resending ? null : onResend,
            icon: resending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.forward_to_inbox_rounded),
            label: Text(strings.syncResendEmail),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: resending ? null : onBackToSignIn,
            child: Text(strings.syncSignIn),
          ),
        ),
      ],
    );
  }
}
