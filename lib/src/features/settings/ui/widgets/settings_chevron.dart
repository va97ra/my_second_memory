import 'package:flutter/material.dart';

/// Стрелка в углу плитки: нажатие откроет другой экран.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
}
