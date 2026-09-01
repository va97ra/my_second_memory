import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'electrical_input_grid.dart';
import 'electrical_mode.dart';
import 'electrical_output_panel.dart';
import 'engineering_disclaimer.dart';
import 'engineering_mode_picker.dart';
import 'engineering_helpers.dart';
import 'engineering_network_section.dart';
import 'engineering_section.dart';
import 'ohm_law_calculator.dart';
import 'voltage_drop_calculator.dart';
import 'wire_sizing_calculator.dart';

/// Электрика: выбор расчёта и сам расчёт.
///
/// Падение напряжения и подбор сечения — самостоятельные экраны со своими
/// полями; здесь остаются мощность и раскладка по фазам.
class ElectricalCalculator extends ConsumerStatefulWidget {
  const ElectricalCalculator({super.key});

  @override
  ConsumerState<ElectricalCalculator> createState() => _ElectricalState();
}

class _ElectricalState extends ConsumerState<ElectricalCalculator> {
  final _voltage = TextEditingController(text: singlePhaseVoltage);
  final _current = TextEditingController(text: '10');
  final _factor = TextEditingController(text: '0.9');
  final _efficiency = TextEditingController(text: '0.95');
  final _loads = TextEditingController(text: '2000, 1500, 1200, 800');
  ElectricalMode _mode = ElectricalMode.power;
  bool _threePhase = false;

  @override
  void dispose() {
    for (final item in [
      _voltage,
      _current,
      _factor,
      _efficiency,
      _loads,
    ]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EngineeringModePicker<ElectricalMode>(
          value: _mode,
          options: [
            (ElectricalMode.ohmLaw, strings.ohmLaw),
            (ElectricalMode.power, strings.power),
            (ElectricalMode.voltageDrop, strings.voltageDrop),
            (ElectricalMode.phases, strings.phases),
            (ElectricalMode.wireSizing, strings.wireSizing),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 12),
        switch (_mode) {
          ElectricalMode.ohmLaw => const OhmLawCalculator(),
          ElectricalMode.wireSizing => const WireSizingCalculator(),
          ElectricalMode.voltageDrop => const VoltageDropCalculator(),
          ElectricalMode.power => _power(strings),
          ElectricalMode.phases => _phases(strings),
        },
      ],
    );
  }

  /// Общая рамка расчёта: оговорка под ответом.
  Widget _framed(List<Widget> children) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: 12),
          const EngineeringDisclaimer(),
        ],
      );

  Widget _power(AppStrings strings) => _framed([
          EngineeringNetworkSection(
            voltage: _voltage,
            threePhase: _threePhase,
            onThreePhaseChanged: (value) =>
                setState(() => _threePhase = value),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 8),
          EngineeringSection(
            title: strings.loadSection,
            children: [
              ElectricalInputGrid(
                current: _current,
                factor: _factor,
                efficiency: _efficiency,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElectricalOutputPanel(
            mode: _mode,
            voltage: _voltage.text,
            current: _current.text,
            factor: _factor.text,
            extra: _efficiency.text,
            threePhase: _threePhase,
          ),
      ]);

  Widget _phases(AppStrings strings) => _framed([
          EngineeringSection(
            title: strings.loadSection,
            children: [
              ElectricalOutputPanel(
                mode: _mode,
                loads: _loads.text,
                onChanged: () => setState(() {}),
                loadsController: _loads,
              ),
            ],
          ),
      ]);
}
