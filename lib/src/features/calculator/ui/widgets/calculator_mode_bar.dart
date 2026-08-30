import 'package:flutter/material.dart';

/// Высота полосы выбора режима: её держит сама полоса, а не экран вокруг.
const double calculatorModeBarHeight = 40;

class CalculatorModeBar extends StatelessWidget {
  const CalculatorModeBar({
    required this.standardLabel,
    required this.scientificLabel,
    required this.scientific,
    required this.onModeChanged,
    super.key,
  });

  final String standardLabel;
  final String scientificLabel;
  final bool scientific;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
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

  Widget _label(String value) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}
