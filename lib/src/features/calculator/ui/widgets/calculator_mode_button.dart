import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// One glass mode selector used by screen themes.
class CalculatorModeButton extends StatelessWidget {
  const CalculatorModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenVisuals.maybeOf(context)!.colors;
    return ScreenGlassButton(
      key: const ValueKey('calculator_mode_glass_button'),
      opacity: selected ? 0.62 : 0.22,
      tint: selected ? screen.accent : screen.panel,
      selected: selected,
      semanticLabel: label,
      onPressed: onPressed,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? screen.onAccent : screen.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
