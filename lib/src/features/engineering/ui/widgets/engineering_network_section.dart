import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_choice.dart';
import 'engineering_helpers.dart';
import 'engineering_section.dart';

/// Блок «Сеть»: сколько фаз и какое напряжение.
///
/// Блок один на все электрические расчёты — и число фаз, и правило о
/// стандартном напряжении живут здесь, а не копией в каждом экране.
class EngineeringNetworkSection extends StatelessWidget {
  const EngineeringNetworkSection({
    required this.voltage,
    required this.threePhase,
    required this.onThreePhaseChanged,
    required this.onChanged,
    super.key,
  });

  final TextEditingController voltage;
  final bool threePhase;
  final ValueChanged<bool> onThreePhaseChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return EngineeringSection(
      title: strings.networkSection,
      children: [
        EngineeringChoice<bool>(
          value: threePhase,
          options: [
            (false, strings.singlePhaseNetwork),
            (true, strings.threePhaseNetwork),
          ],
          onChanged: (value) {
            voltage.text = voltageForPhases(
              text: voltage.text,
              threePhase: value,
            );
            onThreePhaseChanged(value);
          },
        ),
        const SizedBox(height: 12),
        ToolNumberField(
          controller: voltage,
          label: strings.voltage,
          suffix: EngUnit.volt.symbol(strings.isRu),
          hint: strings.hintVoltage,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
