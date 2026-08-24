import 'package:flutter/material.dart';

/// Значок и заголовок в шапке карточки замка.
class SecurityCardTitle extends StatelessWidget {
  const SecurityCardTitle({
    super.key,
    required this.icon,
    required this.title,
    this.iconSize = 42,
    this.large = false,
  });

  final IconData icon;
  final String title;
  final double iconSize;

  /// Название приложения набирается крупнее, чем вопрос в карточке.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        large ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: style?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
