import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_mode_picker.dart';
import 'engineering_disclaimer.dart';
import 'engineering_input_grid.dart';
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
  final _deltaT = TextEditingController(text: '20');
  final _people = TextEditingController(text: '4');
  final _perPerson = TextEditingController(text: '60');
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
      _ach,
      _deltaT,
      _people,
      _perPerson,
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
        EngineeringModePicker<VentilationMode>(
          value: _mode,
          options: [
            (VentilationMode.duct, strings.duct),
            (VentilationMode.room, strings.airExchange),
            (VentilationMode.heater, strings.heater),
            (VentilationMode.people, strings.byPeople),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 8),
        EngineeringInputGrid(
          children: _mode == VentilationMode.people
              ? [
                  ToolNumberField(
                      controller: _people,
                      label: strings.peopleCount,
                      suffix: EngUnit.person.symbol(ru),
                      hint: strings.hintPeopleCount,
                      onChanged: (_) => setState(() {})),
                  ToolNumberField(
                      controller: _perPerson,
                      label: strings.airPerPerson,
                      suffix: EngUnit.cubicMetrePerHour.symbol(ru),
                      hint: strings.hintAirPerPerson,
                      onChanged: (_) => setState(() {})),
                ]
              : _mode == VentilationMode.heater
              ? [
                  ToolNumberField(
                      controller: _flow,
                      label: strings.airflow,
                      suffix: EngUnit.cubicMetrePerHour.symbol(ru),
                      hint: strings.hintAirflow,
                      onChanged: (_) => setState(() {})),
                  ToolNumberField(
                      controller: _deltaT,
                      label: strings.deltaTemperature,
                      suffix: EngUnit.celsius.symbol(ru),
                      hint: strings.hintDeltaAir,
                      onChanged: (_) => setState(() {})),
                ]
              : _mode == VentilationMode.duct
              ? [
                  ToolNumberField(
                      controller: _flow,
                      label: strings.airflow,
                      suffix: EngUnit.cubicMetrePerHour.symbol(ru),
                      hint: strings.hintAirflow,
                      onChanged: (_) => setState(() {})),
                  ToolNumberField(
                      controller: _width,
                      label: strings.width,
                      suffix: EngUnit.millimetre.symbol(ru),
                      hint: strings.hintDuctSide,
                      onChanged: (_) => setState(() {})),
                  ToolNumberField(
                      controller: _height,
                      label: strings.height,
                      suffix: EngUnit.millimetre.symbol(ru),
                      hint: strings.hintDuctSide,
                      onChanged: (_) => setState(() {})),
                  ToolNumberField(
                      controller: _velocity,
                      label: strings.targetVelocity,
                      suffix: EngUnit.metrePerSecond.symbol(ru),
                      hint: strings.hintTargetVelocity,
                      onChanged: (_) => setState(() {})),
                ]
              : [
                  ToolNumberField(
                      controller: _roomLength,
                      label: strings.roomLength,
                      suffix: EngUnit.metre.symbol(ru),
                      hint: strings.hintRoomSide,
                      onChanged: (_) => setState(() {})),
                  ToolNumberField(
                      controller: _roomWidth,
                      label: strings.roomWidth,
                      suffix: EngUnit.metre.symbol(ru),
                      hint: strings.hintRoomSide,
                      onChanged: (_) => setState(() {})),
                  ToolNumberField(
                      controller: _roomHeight,
                      label: strings.roomHeight,
                      suffix: EngUnit.metre.symbol(ru),
                      hint: strings.hintRoomSide,
                      onChanged: (_) => setState(() {})),
                  ToolNumberField(
                      controller: _ach,
                      label: strings.airChanges,
                      suffix: EngUnit.perHour.symbol(ru),
                      hint: strings.hintAirChanges,
                      onChanged: (_) => setState(() {})),
                ],
        ),
        const SizedBox(height: 8),
        VentilationOutputPanel(
            mode: _mode,
            flow: _flow.text,
            width: _width.text,
            height: _height.text,
            velocity: _velocity.text,
            roomLength: _roomLength.text,
            roomWidth: _roomWidth.text,
            roomHeight: _roomHeight.text,
            ach: _ach.text,
            deltaTemperature: _deltaT.text,
            people: _people.text,
            perPerson: _perPerson.text),
        const SizedBox(height: 12),
        const EngineeringDisclaimer(),
      ],
    );
  }
}
