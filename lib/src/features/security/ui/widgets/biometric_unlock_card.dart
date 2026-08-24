import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'security_card.dart';
import 'security_card_title.dart';
import 'security_error_text.dart';
import 'security_primary_button.dart';

/// Разблокировка отпечатком или лицом, с переходом на PIN.
class BiometricUnlockCard extends StatelessWidget {
  const BiometricUnlockCard({
    super.key,
    required this.busy,
    required this.error,
    required this.onRetry,
    required this.onShowPin,
  });

  final bool busy;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onShowPin;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SecurityCard(
      children: [
        SecurityCardTitle(
          icon: Icons.fingerprint_rounded,
          title: strings.appTitle,
          iconSize: 52,
          large: true,
        ),
        const SizedBox(height: 18),
        SecurityPrimaryButton(
          busy: busy,
          icon: Icons.fingerprint_rounded,
          label: strings.tryBiometricsAgain,
          onPressed: onRetry,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onShowPin,
            icon: const Icon(Icons.password_rounded),
            label: Text(strings.unlockWithPin),
          ),
        ),
        if (error != null) SecurityErrorText(error!),
      ],
    );
  }
}
