import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_choice.dart';
import 'engineering_network_section.dart';
import 'engineering_input_grid.dart';
import 'engineering_section.dart';

/// Блоки «Сеть» и «Нагрузка»: откуда напряжение и что линия питает.
///
/// Нагрузку вводят и током, и мощностью: на объекте известно то одно, то
/// другое, и пересчитывать в уме не должен человек.
class VoltageDropSupplySection extends StatelessWidget {
  const VoltageDropSupplySection({
    required this.voltage,
    required this.current,
    required this.power,
    required this.factor,
    required this.threePhase,
    required this.loadIsPower,
    required this.onThreePhaseChanged,
    required this.onLoadIsPowerChanged,
    required this.onChanged,
    super.key,
  });

  final TextEditingController voltage;
  final TextEditingController current;
  final TextEditingController power;
  final TextEditingController factor;
  final bool threePhase;
  final bool loadIsPower;
  final ValueChanged<bool> onThreePhaseChanged;
  final ValueChanged<bool> onLoadIsPowerChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EngineeringNetworkSection(
          voltage: voltage,
          threePhase: threePhase,
          onThreePhaseChanged: onThreePhaseChanged,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        EngineeringSection(
          title: strings.loadSection,
          children: [
            EngineeringChoice<bool>(
              value: loadIsPower,
              options: [
                (false, strings.byCurrent),
                (true, strings.byPower),
              ],
              onChanged: onLoadIsPowerChanged,
            ),
            const SizedBox(height: 12),
            EngineeringInputGrid(
              children: [
                if (loadIsPower)
                  ToolNumberField(
                    controller: power,
                    label: strings.loadPower,
                    suffix: EngUnit.kilowatt.symbol(ru),
                    hint: strings.hintLoadPower,
                    onChanged: (_) => onChanged(),
                  )
                else
                  ToolNumberField(
                    controller: current,
                    label: strings.loadCurrent,
                    suffix: EngUnit.ampere.symbol(ru),
                    hint: strings.hintLoadCurrent,
                    onChanged: (_) => onChanged(),
                  ),
                ToolNumberField(
                  controller: factor,
                  label: 'cos φ',
                  hint: strings.hintPowerFactor,
                  onChanged: (_) => onChanged(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
