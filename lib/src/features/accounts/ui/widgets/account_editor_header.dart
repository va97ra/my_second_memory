import 'package:flutter/material.dart';

/// Шапка редактора аккаунта: значок, заголовок и кнопка закрытия.
class AccountEditorHeader extends StatelessWidget {
  const AccountEditorHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(Icons.vpn_key_rounded, color: colors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
