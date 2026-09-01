import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_choice.dart';
import 'engineering_helpers.dart';
import 'engineering_network_section.dart';
import 'engineering_input_grid.dart';
import 'wire_sizing_output_panel.dart';

class WireSizingCalculator extends StatefulWidget {
  const WireSizingCalculator({super.key});

  @override
  State<WireSizingCalculator> createState() => _WireSizingCalculatorState();
}

class _WireSizingCalculatorState extends State<WireSizingCalculator> {
  final _current = TextEditingController(text: '32');
  final _power = TextEditingController(text: '7');
  final _voltage = TextEditingController(text: singlePhaseVoltage);
  final _factor = TextEditingController(text: '0.95');
  ConductorMaterial _material = ConductorMaterial.copper;
  WireRouting _routing = WireRouting.conduitTwo;
  bool _loadIsPower = false;
  bool _threePhase = false;

  @override
  void dispose() {
    for (final item in [_current, _power, _voltage, _factor]) {
      item.dispose();
    }
    super.dispose();
  }

  /// Ток, из которого подбирается сечение. Мощность пересчитывается тем же
  /// правилом, что и в падении напряжения: расчёт один, экранов два.
  String get _currentForSizing {
    if (!_loadIsPower) return _current.text;
    final powerKw = parseToolNumber(_power.text);
    final voltageV = parseToolNumber(_voltage.text);
    final factor = parseToolNumber(_factor.text);
    if (powerKw == null || voltageV == null || voltageV <= 0) return '';
    if (factor == null || factor <= 0 || factor > 1) return '';
    final amperes = _threePhase
        ? threePhaseCurrent(
            powerW: powerKw * 1000,
            lineVoltageV: voltageV,
            powerFactor: factor,
          )
        : singlePhaseCurrent(
            powerW: powerKw * 1000,
            voltageV: voltageV,
            powerFactor: factor,
          );
    return amperes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    return Column(
      children: [
        EngineeringChoice<bool>(
          value: _loadIsPower,
          options: [
            (false, strings.byCurrent),
            (true, strings.byPower),
          ],
          onChanged: (value) => setState(() => _loadIsPower = value),
        ),
        const SizedBox(height: 12),
        if (_loadIsPower) ...[
          EngineeringNetworkSection(
            voltage: _voltage,
            threePhase: _threePhase,
            onThreePhaseChanged: (value) =>
                setState(() => _threePhase = value),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 8),
        ],
        EngineeringInputGrid(
          children: [
            if (_loadIsPower) ...[
              ToolNumberField(
                controller: _power,
                label: strings.loadPower,
                suffix: EngUnit.kilowatt.symbol(ru),
                hint: strings.hintLoadPower,
                onChanged: (_) => setState(() {}),
              ),
              ToolNumberField(
                controller: _factor,
                label: 'cos φ',
                hint: strings.hintPowerFactor,
                onChanged: (_) => setState(() {}),
              ),
            ] else
              ToolNumberField(
                controller: _current,
                label: strings.loadCurrent,
                suffix: EngUnit.ampere.symbol(ru),
                hint: strings.hintLoadCurrent,
                onChanged: (_) => setState(() {}),
              ),
            DropdownButtonFormField<ConductorMaterial>(
              key: ValueKey(_material),
              initialValue: _material,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.conductorMaterial,
                helperText: strings.hintMaterial,
                helperMaxLines: 3,
              ),
              items: [
                DropdownMenuItem(
                  value: ConductorMaterial.copper,
                  child: Text(strings.copper),
                ),
                DropdownMenuItem(
                  value: ConductorMaterial.aluminium,
                  child: Text(strings.aluminium),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _material = value);
              },
            ),
            DropdownButtonFormField<WireRouting>(
              key: ValueKey(_routing),
              initialValue: _routing,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.wireRouting,
                helperText: strings.hintRouting,
                helperMaxLines: 3,
              ),
              items: [
                for (final routing in WireRouting.values)
                  DropdownMenuItem(
                    value: routing,
                    child: Text(wireRoutingLabel(strings, routing)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _routing = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        WireSizingOutputPanel(
          current: _currentForSizing,
          material: _material,
          routing: _routing,
        ),
      ],
    );
  }
}
