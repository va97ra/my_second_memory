import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Мягкий переключатель в углу плитки. Только показывает: нажимается вся плитка.
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({super.key, required this.value});

  static const _duration = Duration(milliseconds: 150);

  final bool value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOutCubic,
      width: 34,
      height: 20,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color:
            value ? colors.primary : colors.onSurface.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: AnimatedAlign(
        duration: _duration,
        curve: Curves.easeOutCubic,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: const SizedBox.square(
          dimension: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppPalette.paper,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
