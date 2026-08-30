import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({
    required this.controller,
    required this.evaluation,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final CalculatorEvaluation evaluation;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final result = _result(strings);
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('calculator_display'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            SizedBox(
              height: 42,
              child: TextField(
                key: const ValueKey('calculator_expression'),
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                maxLines: 1,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    tooltip: strings.calculatorCopyResult,
                    onPressed: evaluation.value == null
                        ? null
                        : () => Clipboard.setData(
                              ClipboardData(text: result),
                            ),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: DecoratedBox(
                      key: const ValueKey('calculator_result_panel'),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.44,
                        ),
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _result(AppStrings strings) {
    if (evaluation.value case final value?) {
      return calculatorDisplayValue(value);
    }
    if (evaluation.error case final error?) {
      return strings.calculatorError(error.name);
    }
    return strings.calculatorIncomplete;
  }
}

String calculatorDisplayValue(String value) {
  return value.startsWith('-') ? '−${value.substring(1)}' : value;
}
