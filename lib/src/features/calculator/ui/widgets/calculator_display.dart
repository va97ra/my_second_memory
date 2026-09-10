import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator_result_panel.dart';

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
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    final content = Padding(
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
                  style: screen == null
                      ? null
                      : IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: screen.ink,
                          side: BorderSide(
                            color: screen.glint.withValues(alpha: 0.56),
                          ),
                        ),
                  onPressed: evaluation.value == null
                      ? null
                      : () => Clipboard.setData(ClipboardData(text: result)),
                  icon: const Icon(Icons.copy_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: CalculatorResultPanel(
                    result: result,
                    screen: screen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (screen == null) {
      return Card(
        key: const ValueKey('calculator_display'),
        margin: EdgeInsets.zero,
        child: content,
      );
    }
    return ScreenGlassSurface(
      key: const ValueKey('calculator_display'),
      colors: screen,
      opacity: screen.isDark ? 0.38 : 0.22,
      painterKey: const ValueKey('calculator_display_glass'),
      child: content,
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
