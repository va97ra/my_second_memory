import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'security_card.dart';
import 'security_card_title.dart';

/// Защищённое хранилище не открылось.
///
/// Дальше идти некуда: без него данные не расшифровать, поэтому предлагается
/// либо повторить, либо закрыть приложение.
class SecureStorageErrorCard extends StatelessWidget {
  const SecureStorageErrorCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SecurityCard(
      children: [
        SecurityCardTitle(
          icon: Icons.shield_rounded,
          title: strings.secureStorageStartFailed,
          iconSize: 52,
        ),
        const SizedBox(height: 8),
        Text(
          strings.secureStorageStartFailedSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.retry),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: SystemNavigator.pop,
            child: Text(strings.closeApp),
          ),
        ),
      ],
    );
  }
}
