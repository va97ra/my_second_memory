import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/page_hint_button.dart';
import 'calculator_mode_button.dart';

/// Высота полосы выбора режима: её держит сама полоса, а не экран вокруг.
const double calculatorModeBarHeight = 40;

/// Полоса над калькулятором: подсказка страницы и выбор режима.
///
/// Подсказка стоит в этом же ряду, а не строкой над ним: шапки у калькулятора
/// нет, и отдельная строка отнималась бы у клавиатуры.
class CalculatorModeBar extends StatelessWidget {
  const CalculatorModeBar({
    required this.hint,
    required this.standardLabel,
    required this.scientificLabel,
    required this.scientific,
    required this.onModeChanged,
    super.key,
  });

  final String hint;
  final String standardLabel;
  final String scientificLabel;
  final bool scientific;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenVisuals.maybeOf(context);
    return SizedBox(
      height: calculatorModeBarHeight,
      child: Row(
        children: [
          PageHintButton(hint: hint),
          Expanded(
            child: screen == null ? _notebookModes() : _glassModes(),
          ),
        ],
      ),
    );
  }

  Widget _notebookModes() {
    return SegmentedButton<bool>(
      key: const ValueKey('calculator_mode'),
      segments: [
        ButtonSegment(value: false, label: _label(standardLabel)),
        ButtonSegment(value: true, label: _label(scientificLabel)),
      ],
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      // Сжатая плотность отнимала у сегмента 8 px, а рамку полосы рисуют по
      // полной высоте: заливка не доходила ни до низа, ни до скруглённых углов.
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStatePropertyAll(
          Size.fromHeight(calculatorModeBarHeight),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      selected: {scientific},
      onSelectionChanged: (value) => onModeChanged(value.single),
    );
  }

  Widget _glassModes() => SizedBox(
        key: const ValueKey('calculator_mode'),
        child: Row(
          children: [
            Expanded(
              child: CalculatorModeButton(
                label: standardLabel,
                selected: !scientific,
                onPressed: () => onModeChanged(false),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: CalculatorModeButton(
                label: scientificLabel,
                selected: scientific,
                onPressed: () => onModeChanged(true),
              ),
            ),
          ],
        ),
      );

  Widget _label(String value) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}
