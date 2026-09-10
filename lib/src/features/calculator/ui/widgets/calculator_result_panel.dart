import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

class CalculatorResultPanel extends StatelessWidget {
  const CalculatorResultPanel({
    required this.result,
    required this.screen,
    super.key,
  });

  final String result;
  final ScreenThemeColors? screen;

  @override
  Widget build(BuildContext context) {
    final screen = this.screen;
    final colors = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SelectableText(
            result,
            key: const ValueKey('calculator_result'),
            maxLines: 1,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
    if (screen == null) {
      return DecoratedBox(
        key: const ValueKey('calculator_result_panel'),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.44),
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: content,
      );
    }
    return ScreenGlassSurface(
      key: const ValueKey('calculator_result_panel'),
      colors: screen,
      opacity: screen.isDark ? 0.24 : 0.14,
      tint: colors.surfaceContainerHighest,
      showShadow: false,
      painterKey: const ValueKey('calculator_result_glass'),
      child: content,
    );
  }
}
