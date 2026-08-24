import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'sync_card.dart';
import 'sync_error_text.dart';

/// Пароль зашифрованного хранилища — или код восстановления вместо него.
class SyncVaultForm extends StatelessWidget {
  const SyncVaultForm({
    super.key,
    required this.passwordController,
    required this.confirmationController,
    required this.busy,
    required this.vaultExists,
    required this.recoveryMode,
    required this.obscurePassword,
    required this.errorText,
    required this.onToggleObscure,
    required this.onToggleRecovery,
    required this.onSubmit,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmationController;
  final bool busy;
  final bool vaultExists;
  final bool recoveryMode;
  final bool obscurePassword;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleRecovery;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SyncCard(
      icon: Icons.enhanced_encryption_rounded,
      title: strings.syncVaultPassword,
      children: [
        Text(vaultExists ? strings.syncExistingVault : strings.syncNewVault),
        const SizedBox(height: 8),
        Text(
          strings.syncVaultPasswordHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('sync_vault_password'),
          controller: passwordController,
          enabled: !busy,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: recoveryMode
                ? strings.syncRecoveryCode
                : strings.syncVaultPassword,
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
        ),
        // Новое хранилище набирают дважды: забытый пароль восстановить нечем.
        if (!vaultExists && !recoveryMode) ...[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('sync_vault_confirmation'),
            controller: confirmationController,
            enabled: !busy,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: strings.syncRepeatVaultPassword,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 12),
          SyncErrorText(errorText!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            key: const ValueKey('sync_vault_submit'),
            onPressed: busy ? null : onSubmit,
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(strings.syncConnect),
          ),
        ),
        if (vaultExists) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: busy ? null : onToggleRecovery,
              child: Text(
                recoveryMode
                    ? strings.syncUsePassword
                    : strings.syncUseRecoveryCode,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
