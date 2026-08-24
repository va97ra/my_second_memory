import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'sync_card.dart';

/// Сборка без адреса облака: синхронизировать не с чем.
class SyncUnconfiguredCard extends StatelessWidget {
  const SyncUnconfiguredCard({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SyncCard(
      icon: Icons.cloud_off_rounded,
      title: strings.syncNotConfigured,
      children: [
        Text(strings.syncNotConfiguredHint),
        const SizedBox(height: 12),
        const SelectableText(
          '--dart-define=SUPABASE_URL=…\n'
          '--dart-define=SUPABASE_PUBLISHABLE_KEY=…',
        ),
      ],
    );
  }
}
