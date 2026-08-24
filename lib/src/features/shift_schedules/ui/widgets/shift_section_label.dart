import 'package:flutter/material.dart';

/// Подпись раздела в редакторе графика.
class ShiftSectionLabel extends StatelessWidget {
  const ShiftSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
