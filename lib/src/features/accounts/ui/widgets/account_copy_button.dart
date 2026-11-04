import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'account_row_button.dart';

/// Кнопка копирования поля аккаунта. Одна на все поля карточки.
class AccountCopyButton extends StatelessWidget {
  const AccountCopyButton({
    super.key,
    required this.text,
    required this.tooltip,
    required this.copiedMessage,
  });

  final String text;
  final String tooltip;
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    return AccountRowButton(
      icon: Icons.content_copy_rounded,
      tooltip: tooltip,
      onPressed: () => _copy(context),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copiedMessage)),
    );
  }
}
