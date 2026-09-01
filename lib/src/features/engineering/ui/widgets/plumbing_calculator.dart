import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_disclaimer.dart';
import 'engineering_input_grid.dart';
import 'engineering_mode_picker.dart';
import 'plumbing_mode.dart';
import 'plumbing_output_panel.dart';

class PlumbingCalculator extends ConsumerStatefulWidget {
  const PlumbingCalculator({super.key});

  @override
  ConsumerState<PlumbingCalculator> createState() => _PlumbingState();
}

class _PlumbingState extends ConsumerState<PlumbingCalculator> {
  final _flow = TextEditingController(text: '60');
  final _diameter = TextEditingController(text: '25');
  final _velocity = TextEditingController(text: '1');
  final _length = TextEditingController(text: '10');
  final _head = TextEditingController(text: '10');
  final _roughness = TextEditingController(text: '0.01');
  final _power = TextEditingController(text: '10');
  final _deltaT = TextEditingController(text: '20');
  final _slope = TextEditingController(text: '2');
  PlumbingMode _mode = PlumbingMode.flow;

  @override
  void dispose() {
    for (final item in [
      _flow,
      _diameter,
      _velocity,
      _length,
      _head,
      _roughness,
      _power,
      _deltaT,
      _slope,
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
        EngineeringModePicker<PlumbingMode>(
          value: _mode,
          options: [
            (PlumbingMode.flow, strings.flow),
            (PlumbingMode.volume, strings.pipe),
            (PlumbingMode.pressure, strings.pressure),
            (PlumbingMode.heating, strings.heating),
            (PlumbingMode.slope, strings.slope),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 8),
        EngineeringInputGrid(children: _fields(strings)),
        const SizedBox(height: 8),
        PlumbingOutputPanel(
          mode: _mode,
          flow: _flow.text,
          diameter: _diameter.text,
          third: _mode == PlumbingMode.flow ? _velocity.text : _length.text,
          head: _head.text,
          roughness: _roughness.text,
          power: _power.text,
          deltaTemperature: _deltaT.text,
          slope: _slope.text,
        ),
        const SizedBox(height: 12),
        const EngineeringDisclaimer(),
      ],
    );
  }

  /// Поля своего расчёта и ничьи больше: пустая графа от соседнего режима
  /// заставляет гадать, участвует она в ответе или нет.
  List<Widget> _fields(AppStrings strings) {
    final ru = strings.isRu;
    ToolNumberField field(
      TextEditingController controller,
      String label,
      EngUnit unit,
      String hint,
    ) =>
        ToolNumberField(
          controller: controller,
          label: label,
          suffix: unit.symbol(ru),
          hint: hint,
          onChanged: (_) => setState(() {}),
        );
    return switch (_mode) {
      PlumbingMode.heating => [
          field(_power, strings.heatPower, EngUnit.kilowatt,
              strings.hintHeatPower),
          field(_deltaT, strings.deltaTemperature, EngUnit.celsius,
              strings.hintDeltaWater),
        ],
      PlumbingMode.slope => [
          field(_slope, strings.slope, EngUnit.percent, strings.hintSlope),
          field(_length, strings.sectionLength, EngUnit.metre,
              strings.hintPipeLength),
        ],
      PlumbingMode.flow => [
          field(_flow, strings.flow, EngUnit.litrePerMinute, strings.hintFlow),
          field(_diameter, strings.internalDiameter, EngUnit.millimetre,
              strings.hintInternalDiameter),
          field(_velocity, strings.targetVelocity, EngUnit.metrePerSecond,
              strings.hintTargetVelocity),
        ],
      PlumbingMode.volume => [
          field(_flow, strings.flow, EngUnit.litrePerMinute, strings.hintFlow),
          field(_diameter, strings.internalDiameter, EngUnit.millimetre,
              strings.hintInternalDiameter),
          field(_length, strings.pipeLength, EngUnit.metre,
              strings.hintPipeLength),
        ],
      PlumbingMode.pressure => [
          field(_flow, strings.flow, EngUnit.litrePerMinute, strings.hintFlow),
          field(_diameter, strings.internalDiameter, EngUnit.millimetre,
              strings.hintInternalDiameter),
          field(_length, strings.pipeLength, EngUnit.metre,
              strings.hintPipeLength),
          field(_head, strings.head, EngUnit.metreOfWater, strings.hintHead),
          field(_roughness, strings.roughness, EngUnit.millimetre,
              strings.hintRoughness),
        ],
    };
  }
}
