import 'package:flutter/material.dart';

class CalculatorResultPanel extends StatelessWidget {
  const CalculatorResultPanel({
    required this.result,
    super.key,
  });

  final String result;

  @override
  Widget build(BuildContext context) {
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
}
