import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sync_card.dart';

/// Код восстановления хранилища. Показывается один раз, поэтому рядом с ним
/// сразу кнопка копирования.
class SyncRecoveryCodeCard extends StatelessWidget {
  const SyncRecoveryCodeCard({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SyncCard(
      icon: Icons.key_rounded,
      title: strings.syncRecoveryCode,
      children: [
        Text(strings.syncRecoveryWarning),
        const SizedBox(height: 12),
        SelectableText(
          code,
          key: const ValueKey('sync_recovery_code'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton.filledTonal(
            tooltip: strings.copyPassword,
            onPressed: () => Clipboard.setData(ClipboardData(text: code)),
            icon: const Icon(Icons.copy_rounded),
          ),
        ),
      ],
    );
  }
}
