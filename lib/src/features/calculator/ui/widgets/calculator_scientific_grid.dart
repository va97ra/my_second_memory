import 'package:flutter/material.dart';

import 'calculator_key_grid.dart';

class CalculatorScientificGrid extends StatelessWidget {
  const CalculatorScientificGrid({
    required this.keys,
    required this.onKey,
    required this.wide,
    this.selectedKeys = const {},
    this.labels = const {},
    super.key,
  });

  final List<String> keys;
  final ValueChanged<String> onKey;
  final bool wide;
  final Set<String> selectedKeys;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return _grid(keys);
    }
    final split = keys.length ~/ 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _grid(keys.take(split).toList())),
        const SizedBox(width: 8),
        Expanded(child: _grid(keys.skip(split).toList())),
      ],
    );
  }

  Widget _grid(List<String> visibleKeys) => CalculatorKeyGrid(
        columns: 5,
        keys: visibleKeys,
        selectedKeys: selectedKeys,
        labels: labels,
        onKey: onKey,
      );
}
