import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_choice.dart';
import 'engineering_input_grid.dart';
import 'engineering_section.dart';
import 'ohm_law_output_panel.dart';

/// Закон Ома: две величины известны, третью считает приложение.
///
/// Поля меняются вслед за выбором: искомую величину не вводят, а находят,
/// и держать для неё пустую графу — значит предлагать ввести ответ.
class OhmLawCalculator extends StatefulWidget {
  const OhmLawCalculator({super.key});

  @override
  State<OhmLawCalculator> createState() => _OhmLawCalculatorState();
}

class _OhmLawCalculatorState extends State<OhmLawCalculator> {
  final _voltage = TextEditingController(text: '230');
  final _current = TextEditingController(text: '5');
  final _resistance = TextEditingController(text: '46');
  OhmLawUnknown _unknown = OhmLawUnknown.voltage;

  @override
  void dispose() {
    for (final item in [_voltage, _current, _resistance]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EngineeringSection(
          title: strings.whatToFind,
          children: [
            EngineeringChoice<OhmLawUnknown>(
              value: _unknown,
              options: [
                (OhmLawUnknown.voltage, strings.voltage),
                (OhmLawUnknown.current, strings.current),
                (OhmLawUnknown.resistance, strings.resistance),
              ],
              onChanged: (value) => setState(() => _unknown = value),
            ),
            const SizedBox(height: 12),
            EngineeringInputGrid(
              children: [
                if (_unknown != OhmLawUnknown.voltage)
                  ToolNumberField(
                    controller: _voltage,
                    label: strings.voltage,
                    suffix: EngUnit.volt.symbol(ru),
                    hint: strings.hintVoltage,
                    onChanged: (_) => setState(() {}),
                  ),
                if (_unknown != OhmLawUnknown.current)
                  ToolNumberField(
                    controller: _current,
                    label: strings.current,
                    suffix: EngUnit.ampere.symbol(ru),
                    hint: strings.hintLoadCurrent,
                    onChanged: (_) => setState(() {}),
                  ),
                if (_unknown != OhmLawUnknown.resistance)
                  ToolNumberField(
                    controller: _resistance,
                    label: strings.resistance,
                    suffix: EngUnit.ohm.symbol(ru),
                    hint: strings.hintResistance,
                    onChanged: (_) => setState(() {}),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        OhmLawOutputPanel(
          unknown: _unknown,
          voltage: _voltage.text,
          current: _current.text,
          resistance: _resistance.text,
        ),
      ],
    );
  }
}
