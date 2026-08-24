import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'security_card.dart';
import 'security_card_title.dart';
import 'security_primary_button.dart';

/// Предложение включить биометрию сразу после создания PIN.
class EnableBiometricsCard extends StatelessWidget {
  const EnableBiometricsCard({
    super.key,
    required this.busy,
    required this.onEnable,
    required this.onSkip,
  });

  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SecurityCard(
      children: [
        SecurityCardTitle(
          icon: Icons.fingerprint_rounded,
          title: strings.enableBiometricsQuestion,
          iconSize: 52,
        ),
        const SizedBox(height: 18),
        SecurityPrimaryButton(
          busy: busy,
          icon: Icons.fingerprint_rounded,
          label: strings.biometrics,
          onPressed: onEnable,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: busy ? null : onSkip,
            child: Text(strings.maybeLater),
          ),
        ),
      ],
    );
  }
}
