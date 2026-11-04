import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Кнопка копирования поля аккаунта. Одна на все поля карточки.
class AccountCopyButton extends StatelessWidget {
  const AccountCopyButton({
    super.key,
    required this.text,
    required this.tooltip,
    required this.copiedMessage,
  });

  static const size = 40.0;

  final String text;
  final String tooltip;
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () => _copy(context),
      constraints: const BoxConstraints.tightFor(width: size, height: size),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.content_copy_rounded, size: 18),
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
