import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Строка состояния защиты: включено или нет.
class SecurityStatusRow extends StatelessWidget {
  const SecurityStatusRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.isEnabled,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isEnabled ? AppPalette.success : colors.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isEnabled
            ? Color.alphaBlend(
                AppPalette.success.withValues(alpha: 0.12),
                colors.surface,
              )
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? AppPalette.successTint : colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
