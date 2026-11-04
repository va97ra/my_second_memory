import 'package:flutter/material.dart';

import 'account_copy_button.dart';

/// Строка сведений аккаунта с кнопкой копирования.
class AccountInfoLine extends StatelessWidget {
  const AccountInfoLine({
    super.key,
    required this.icon,
    required this.text,
    required this.copyTooltip,
    required this.copiedMessage,
  });

  final IconData icon;
  final String text;
  final String copyTooltip;
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 17, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AccountCopyButton(
          text: text,
          tooltip: copyTooltip,
          copiedMessage: copiedMessage,
        ),
      ],
    );
  }
}
