import 'package:flutter/material.dart';

/// Код текущего языка в углу плитки: «RU» или «EN».
class SettingsLanguageMark extends StatelessWidget {
  const SettingsLanguageMark({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      code.toUpperCase(),
      style: TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
