import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_disclaimer.dart';
import 'engineering_helpers.dart';
import 'plumbing_output_panel.dart';
import 'plumbing_mode.dart';

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
  PlumbingMode _mode = PlumbingMode.flow;

  @override
  void dispose() {
    for (final item in [
      _flow,
      _diameter,
      _velocity,
      _length,
      _head,
      _roughness
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
                value: PlumbingMode.flow, label: Text(strings.flow)),
            ButtonSegment(
                value: PlumbingMode.volume, label: Text(strings.pipe)),
            ButtonSegment(
                value: PlumbingMode.pressure,
                label: Text(strings.pressure)),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 16),
        ToolNumberField(
            controller: _flow,
            label: strings.flow,
            suffix: EngUnit.litrePerMinute.symbol(ru),
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        ToolNumberField(
            controller: _diameter,
            label: strings.internalDiameter,
            suffix: EngUnit.millimetre.symbol(ru),
            onChanged: (_) => setState(() {})),
        if (_mode == PlumbingMode.flow) ...[
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _velocity,
              label: strings.targetVelocity,
              suffix: EngUnit.metrePerSecond.symbol(ru),
              onChanged: (_) => setState(() {})),
        ] else ...[
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _length,
              label: strings.pipeLength,
              suffix: EngUnit.metre.symbol(ru),
              onChanged: (_) => setState(() {})),
        ],
        if (_mode == PlumbingMode.pressure) ...[
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _head,
              label: strings.head,
              suffix: EngUnit.metreOfWater.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _roughness,
              label: strings.roughness,
              suffix: EngUnit.millimetre.symbol(ru),
              onChanged: (_) => setState(() {})),
        ],
        const SizedBox(height: 16),
        PlumbingOutputPanel(
            mode: _mode,
            flow: _flow.text,
            diameter: _diameter.text,
            third: _mode == PlumbingMode.flow ? _velocity.text : _length.text,
            head: _head.text,
            roughness: _roughness.text),
        const SizedBox(height: 12),
        const EngineeringDisclaimer(),
      ],
    );
  }
}
