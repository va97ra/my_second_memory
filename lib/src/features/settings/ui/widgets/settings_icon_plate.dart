import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Цветной значок настройки. Выключенная настройка стоит серой.
class SettingsIconPlate extends StatelessWidget {
  const SettingsIconPlate({
    super.key,
    required this.icon,
    required this.color,
    this.lit = true,
  });

  final IconData icon;
  final Color color;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: lit ? color : colors.onSurface.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(
        icon,
        size: 17,
        color: lit ? readableInkOn(color) : colors.onSurfaceVariant,
      ),
    );
  }
}
