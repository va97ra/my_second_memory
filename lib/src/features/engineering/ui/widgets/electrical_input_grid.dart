import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_input_grid.dart';

/// Поля нагрузки для расчёта мощности. Напряжение и число фаз — в блоке
/// «Сеть», потому что это свойство сети, а не нагрузки.
class ElectricalInputGrid extends StatelessWidget {
  const ElectricalInputGrid({
    required this.current,
    required this.factor,
    required this.efficiency,
    required this.onChanged,
    super.key,
  });

  final TextEditingController current;
  final TextEditingController factor;
  final TextEditingController efficiency;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return EngineeringInputGrid(
      children: [
        ToolNumberField(
          controller: current,
          label: strings.loadCurrent,
          suffix: EngUnit.ampere.symbol(strings.isRu),
          hint: strings.hintLoadCurrent,
          onChanged: (_) => onChanged(),
        ),
        ToolNumberField(
          controller: factor,
          label: 'cos φ',
          hint: strings.hintPowerFactor,
          onChanged: (_) => onChanged(),
        ),
        ToolNumberField(
          controller: efficiency,
          label: strings.efficiency,
          hint: strings.hintEfficiency,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
