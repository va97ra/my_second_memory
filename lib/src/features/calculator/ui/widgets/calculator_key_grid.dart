import 'package:flutter/material.dart';

import '../calculator_key_layouts.dart';
import 'calculator_key.dart';

class CalculatorKeyGrid extends StatelessWidget {
  const CalculatorKeyGrid({
    required this.columns,
    required this.keys,
    required this.onKey,
    this.selectedKeys = const {},
    this.labels = const {},
    super.key,
  }) : assert(keys.length % columns == 0);

  final int columns;
  final List<String> keys;
  final ValueChanged<String> onKey;
  final Set<String> selectedKeys;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final rowCount = keys.length ~/ columns;
    return Column(
      children: [
        for (var row = 0; row < rowCount; row++) ...[
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) const SizedBox(width: 8),
                  Expanded(child: _key(keys[row * columns + column])),
                ],
              ],
            ),
          ),
          if (row < rowCount - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _key(String keyValue) => CalculatorKey(
        label: labels[keyValue] ?? _label(keyValue),
        selected: selectedKeys.contains(keyValue),
        role: calculatorKeyRole(keyValue),
        onPressed: () => onKey(keyValue),
      );

  String _label(String value) => switch (value) {
        'backspace' => '⌫',
        'sqrt' => '√',
        'cbrt' => '∛',
        'square' => 'x²',
        'cube' => 'x³',
        'power' => 'xʸ',
        'root' => 'ʸ√x',
        'reciprocal' => '1/x',
        'sign' => '±',
        'abs' => '|x|',
        'factorial' => 'n!',
        'angle' => 'DEG',
        'pi' => 'π',
        _ => value,
      };
}
