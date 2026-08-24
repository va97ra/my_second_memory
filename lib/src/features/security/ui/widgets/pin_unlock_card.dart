import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'pin_field.dart';
import 'security_card.dart';
import 'security_card_title.dart';
import 'security_error_text.dart';
import 'security_primary_button.dart';

/// Разблокировка PIN-кодом.
class PinUnlockCard extends StatelessWidget {
  const PinUnlockCard({
    super.key,
    required this.controller,
    required this.busy,
    required this.error,
    required this.onUnlock,
    this.onBiometrics,
  });

  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onUnlock;

  /// Null, когда биометрия выключена: возвращаться к ней некуда.
  final VoidCallback? onBiometrics;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SecurityCard(
      children: [
        SecurityCardTitle(
          icon: Icons.lock_rounded,
          title: strings.appTitle,
          large: true,
        ),
        const SizedBox(height: 18),
        PinField(
          controller: controller,
          enabled: !busy,
          onSubmitted: onUnlock,
        ),
        const SizedBox(height: 14),
        SecurityPrimaryButton(
          busy: busy,
          icon: Icons.lock_open_rounded,
          label: strings.unlock,
          onPressed: onUnlock,
        ),
        if (onBiometrics != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onBiometrics,
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(strings.biometrics),
            ),
          ),
        ],
        if (error != null) SecurityErrorText(error!),
      ],
    );
  }
}
