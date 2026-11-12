import 'package:flutter/material.dart';

import 'sync_error_text.dart';

/// Низ карточки синхронизации: ошибка, если она есть, и главная кнопка.
class SyncSubmitBlock extends StatelessWidget {
  const SyncSubmitBlock({
    super.key,
    required this.errorText,
    required this.buttonKey,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final String? errorText;
  final Key buttonKey;
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText case final text?) ...[
          const SizedBox(height: 12),
          SyncErrorText(text),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            key: buttonKey,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      ],
    );
  }
}
