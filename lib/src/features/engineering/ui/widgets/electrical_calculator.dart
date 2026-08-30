import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'electrical_output_panel.dart';
import 'electrical_mode.dart';
import 'engineering_disclaimer.dart';
import 'engineering_helpers.dart';

class ElectricalCalculator extends ConsumerStatefulWidget {
  const ElectricalCalculator({super.key});

  @override
  ConsumerState<ElectricalCalculator> createState() => _ElectricalState();
}

class _ElectricalState extends ConsumerState<ElectricalCalculator> {
  final _voltage = TextEditingController(text: '230');
  final _current = TextEditingController(text: '10');
  final _factor = TextEditingController(text: '0.9');
  final _efficiency = TextEditingController(text: '0.95');
  final _length = TextEditingController(text: '20');
  final _section = TextEditingController(text: '2.5');
  final _loads = TextEditingController(text: '2000, 1500, 1200, 800');
  ElectricalMode _mode = ElectricalMode.power;
  bool _threePhase = false;
  bool _copper = true;

  @override
  void dispose() {
    for (final item in [
      _voltage,
      _current,
      _factor,
      _efficiency,
      _length,
      _section,
      _loads
    ]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        engineeringModeSelector(
          value: _mode,
          segments: [
            ButtonSegment(
                value: ElectricalMode.power,
                label: Text(strings.power)),
            ButtonSegment(
                value: ElectricalMode.voltageDrop,
                label: Text(strings.voltageDrop)),
            ButtonSegment(
                value: ElectricalMode.phases,
                label: Text(strings.phases)),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 16),
        if (_mode == ElectricalMode.phases)
          ElectricalOutputPanel(
              mode: _mode,
              loads: _loads.text,
              onChanged: () => setState(() {}),
              loadsController: _loads)
        else ...[
          ToolNumberField(
              controller: _voltage,
              label: strings.voltage,
              suffix: EngUnit.volt.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _current,
              label: strings.current,
              suffix: EngUnit.ampere.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _factor,
              label: 'cos φ',
              onChanged: (_) => setState(() {})),
          if (_mode == ElectricalMode.power) ...[
            const SizedBox(height: 12),
            ToolNumberField(
                controller: _efficiency,
                label: strings.efficiency,
                onChanged: (_) => setState(() {})),
          ] else ...[
            const SizedBox(height: 12),
            ToolNumberField(
                controller: _length,
                label: strings.oneWayLength,
                suffix: EngUnit.metre.symbol(ru),
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            ToolNumberField(
                controller: _section,
                label: strings.conductorSection,
                suffix: EngUnit.millimetreSquared.symbol(ru),
                onChanged: (_) => setState(() {})),
            SwitchListTile(
                value: _copper,
                onChanged: (v) => setState(() => _copper = v),
                title: Text(strings.copperConductor)),
          ],
          SwitchListTile(
              value: _threePhase,
              onChanged: (v) => setState(() {
                    _threePhase = v;
                    if (v && _voltage.text == '230') _voltage.text = '400';
                  }),
              title: Text(strings.threePhaseSystem)),
          ElectricalOutputPanel(
            mode: _mode,
            voltage: _voltage.text,
            current: _current.text,
            factor: _factor.text,
            extra:
                _mode == ElectricalMode.power ? _efficiency.text : _length.text,
            section: _section.text,
            threePhase: _threePhase,
            copper: _copper,
          ),
        ],
        const SizedBox(height: 12),
        const EngineeringDisclaimer(),
      ],
    );
  }
}
