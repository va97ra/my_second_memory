import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'pin_field.dart';
import 'security_card.dart';
import 'security_card_title.dart';
import 'security_error_text.dart';
import 'security_primary_button.dart';

/// Первый запуск: PIN, которым шифруются данные приложения.
class SetupPinCard extends StatelessWidget {
  const SetupPinCard({
    super.key,
    required this.controller,
    required this.busy,
    required this.error,
    required this.onCreatePin,
  });

  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onCreatePin;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SecurityCard(
      children: [
        SecurityCardTitle(
          icon: Icons.shield_rounded,
          title: strings.setupPinTitle,
        ),
        const SizedBox(height: 8),
        Text(
          strings.setupPinSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 18),
        PinField(controller: controller, onSubmitted: onCreatePin),
        const SizedBox(height: 14),
        SecurityPrimaryButton(
          busy: busy,
          icon: Icons.lock_rounded,
          label: strings.createPin,
          onPressed: onCreatePin,
        ),
        if (error != null) SecurityErrorText(error!),
      ],
    );
  }
}
