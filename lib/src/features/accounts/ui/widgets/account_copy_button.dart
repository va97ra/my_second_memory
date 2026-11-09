import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'account_field_button.dart';

/// Кнопка копирования в поле открытого аккаунта. Копирует то, что в поле написано
/// сейчас; у пустого поля её нет.
class AccountCopyButton extends StatelessWidget {
  const AccountCopyButton({
    super.key,
    required this.controller,
    required this.tooltip,
    required this.copiedMessage,
  });

  final TextEditingController controller;
  final String tooltip;
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => value.text.isEmpty
          ? const SizedBox.shrink()
          : AccountFieldButton(
              icon: Icons.content_copy_rounded,
              tooltip: tooltip,
              onPressed: () => _copy(context, value.text),
            ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    // Копируют подряд несколько полей: подтверждения не должны стоять в очереди.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copiedMessage)));
  }
}
