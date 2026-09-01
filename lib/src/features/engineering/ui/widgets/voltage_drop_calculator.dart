import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/voltage_drop_query.dart';
import 'engineering_choice.dart';
import 'engineering_disclaimer.dart';
import 'engineering_helpers.dart';
import 'engineering_section.dart';
import 'voltage_drop_line_section.dart';
import 'voltage_drop_output_panel.dart';
import 'voltage_drop_supply_section.dart';

class VoltageDropCalculator extends StatefulWidget {
  const VoltageDropCalculator({super.key});

  @override
  State<VoltageDropCalculator> createState() => _VoltageDropCalculatorState();
}

class _VoltageDropCalculatorState extends State<VoltageDropCalculator> {
  final _voltage = TextEditingController(text: singlePhaseVoltage);
  final _current = TextEditingController(text: '16');
  final _power = TextEditingController(text: '3.5');
  final _factor = TextEditingController(text: '0.95');
  final _length = TextEditingController(text: '25');
  double _sectionMm2 = 2.5;
  double _limitPercent = 5;
  bool _threePhase = false;
  bool _loadIsPower = false;
  ConductorMaterial _material = ConductorMaterial.copper;
  WireRouting _routing = WireRouting.conduitTwo;

  @override
  void dispose() {
    for (final item in [_voltage, _current, _power, _factor, _length]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoltageDropSupplySection(
          voltage: _voltage,
          current: _current,
          power: _power,
          factor: _factor,
          threePhase: _threePhase,
          loadIsPower: _loadIsPower,
          onThreePhaseChanged: _setThreePhase,
          onLoadIsPowerChanged: (value) =>
              setState(() => _loadIsPower = value),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
        VoltageDropLineSection(
          material: _material,
          routing: _routing,
          sectionMm2: _sectionMm2,
          length: _length,
          onMaterialChanged: (value) => setState(() => _material = value),
          onRoutingChanged: (value) => setState(() => _routing = value),
          onSectionChanged: (value) => setState(() => _sectionMm2 = value),
          onLengthChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
        EngineeringSection(
          title: strings.dropLimitSection,
          children: [
            EngineeringChoice<double>(
              value: _limitPercent,
              options: const [(3.0, '3 %'), (5.0, '5 %')],
              onChanged: (value) => setState(() => _limitPercent = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        VoltageDropOutputPanel(input: _read(strings)),
        const SizedBox(height: 12),
        EngineeringDisclaimer(message: strings.voltageDropUnverifiedWarning),
      ],
    );
  }

  VoltageDropInput _read(AppStrings strings) => readVoltageDropInput(
        strings: strings,
        voltage: _voltage.text,
        load: _loadIsPower ? _power.text : _current.text,
        loadIsPower: _loadIsPower,
        powerFactor: _factor.text,
        length: _length.text,
        sectionMm2: _sectionMm2,
        limitPercent: _limitPercent,
        threePhase: _threePhase,
        material: _material,
        routing: _routing,
      );

  /// Число жил в трубе следует за числом фаз — но выбранную открытую
  /// прокладку не трогает: это уже решение человека, а не следствие сети.
  void _setThreePhase(bool value) {
    setState(() {
      _threePhase = value;
      if (_routing != WireRouting.openAir) {
        _routing = value ? WireRouting.conduitThree : WireRouting.conduitTwo;
      }
    });
  }
}
