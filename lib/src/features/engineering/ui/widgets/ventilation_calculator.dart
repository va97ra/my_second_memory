import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_disclaimer.dart';
import 'engineering_helpers.dart';
import 'ventilation_output_panel.dart';
import 'ventilation_mode.dart';

class VentilationCalculator extends ConsumerStatefulWidget {
  const VentilationCalculator({super.key});

  @override
  ConsumerState<VentilationCalculator> createState() => _VentilationState();
}

class _VentilationState extends ConsumerState<VentilationCalculator> {
  final _flow = TextEditingController(text: '500');
  final _width = TextEditingController(text: '300');
  final _height = TextEditingController(text: '200');
  final _velocity = TextEditingController(text: '3');
  final _roomLength = TextEditingController(text: '5');
  final _roomWidth = TextEditingController(text: '4');
  final _roomHeight = TextEditingController(text: '3');
  final _ach = TextEditingController(text: '2');
  VentilationMode _mode = VentilationMode.duct;

  @override
  void dispose() {
    for (final item in [
      _flow,
      _width,
      _height,
      _velocity,
      _roomLength,
      _roomWidth,
      _roomHeight,
      _ach
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
                value: VentilationMode.duct,
                label: Text(strings.duct)),
            ButtonSegment(
                value: VentilationMode.room,
                label: Text(strings.airExchange)),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 16),
        if (_mode == VentilationMode.duct) ...[
          ToolNumberField(
              controller: _flow,
              label: strings.airflow,
              suffix: EngUnit.cubicMetrePerHour.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _width,
              label: strings.width,
              suffix: EngUnit.millimetre.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _height,
              label: strings.height,
              suffix: EngUnit.millimetre.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _velocity,
              label: strings.targetVelocity,
              suffix: EngUnit.metrePerSecond.symbol(ru),
              onChanged: (_) => setState(() {})),
        ] else ...[
          ToolNumberField(
              controller: _roomLength,
              label: strings.roomLength,
              suffix: EngUnit.metre.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _roomWidth,
              label: strings.roomWidth,
              suffix: EngUnit.metre.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _roomHeight,
              label: strings.roomHeight,
              suffix: EngUnit.metre.symbol(ru),
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          ToolNumberField(
              controller: _ach,
              label: strings.airChanges,
              suffix: ru ? '1/ч' : '1/h',
              onChanged: (_) => setState(() {})),
        ],
        const SizedBox(height: 16),
        VentilationOutputPanel(
            mode: _mode,
            flow: _flow.text,
            width: _width.text,
            height: _height.text,
            velocity: _velocity.text,
            roomLength: _roomLength.text,
            roomWidth: _roomWidth.text,
            roomHeight: _roomHeight.text,
            ach: _ach.text),
        const SizedBox(height: 12),
        const EngineeringDisclaimer(),
      ],
    );
  }
}
