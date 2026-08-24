import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'google_mark.dart';
import 'sync_card.dart';
import 'sync_error_text.dart';

/// Вход в облако или заведение учётной записи.
class SyncAccountForm extends StatelessWidget {
  const SyncAccountForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.busy,
    required this.registerMode,
    required this.obscurePassword,
    required this.errorText,
    required this.onToggleObscure,
    required this.onToggleMode,
    required this.onSubmit,
    required this.onGoogle,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool busy;
  final bool registerMode;
  final bool obscurePassword;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SyncCard(
      icon: Icons.cloud_sync_rounded,
      title: registerMode ? strings.syncCreateAccount : strings.syncSignIn,
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
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                strings.syncOrWithEmail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('sync_email'),
          controller: emailController,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: strings.email),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('sync_account_password'),
          controller: passwordController,
          enabled: !busy,
          obscureText: obscurePassword,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: strings.syncAccountPassword,
            suffixIcon: IconButton(
              tooltip:
                  obscurePassword ? strings.showPassword : strings.hidePassword,
              onPressed: onToggleObscure,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          SyncErrorText(errorText!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            key: const ValueKey('sync_account_submit'),
            onPressed: busy ? null : onSubmit,
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    registerMode
                        ? strings.syncCreateAccount
                        : strings.syncSignIn,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: busy ? null : onToggleMode,
            child: Text(
              registerMode ? strings.syncSignIn : strings.syncCreateAccount,
            ),
          ),
        ),
      ],
    );
  }
}
