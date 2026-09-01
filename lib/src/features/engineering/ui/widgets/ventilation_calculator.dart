import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_choice.dart';
import 'engineering_input_grid.dart';
import 'engineering_mode_picker.dart';
import 'engineering_section.dart';
import 'ventilation_mode.dart';
import 'ventilation_output_panel.dart';

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
  final _perSquareMetre = TextEditingController(text: '3');
  VentilationMode _mode = VentilationMode.duct;
  RoomAirBasis _basis = RoomAirBasis.changes;

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
      _perSquareMetre,
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
        EngineeringModePicker<VentilationMode>(
          value: _mode,
          options: [
            (VentilationMode.duct, strings.duct),
            (VentilationMode.room, strings.airExchange),
            (VentilationMode.heater, strings.heater),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 8),
        ..._fields(strings),
        const SizedBox(height: 8),
        VentilationOutputPanel(
          mode: _mode,
          basis: _basis,
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
          perPerson: _perPerson.text,
          perSquareMetre: _perSquareMetre.text,
        ),
      ],
    );
  }

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
      VentilationMode.duct => [
          EngineeringInputGrid(children: [
            field(_flow, strings.airflow, EngUnit.cubicMetrePerHour,
                strings.hintAirflow),
            field(_width, strings.width, EngUnit.millimetre,
                strings.hintDuctSide),
            field(_height, strings.height, EngUnit.millimetre,
                strings.hintDuctSide),
            field(_velocity, strings.targetVelocity, EngUnit.metrePerSecond,
                strings.hintTargetVelocity),
          ]),
        ],
      VentilationMode.heater => [
          EngineeringInputGrid(children: [
            field(_flow, strings.airflow, EngUnit.cubicMetrePerHour,
                strings.hintAirflow),
            field(_deltaT, strings.deltaTemperature, EngUnit.celsius,
                strings.hintDeltaAir),
          ]),
        ],
      // Помещение спрашивают одинаково, а дальше — по чему считать.
      VentilationMode.room => [
          EngineeringSection(
            title: strings.roomSection,
            children: [
              EngineeringInputGrid(children: [
                field(_roomLength, strings.roomLength, EngUnit.metre,
                    strings.hintRoomSide),
                field(_roomWidth, strings.roomWidth, EngUnit.metre,
                    strings.hintRoomSide),
                if (_basis == RoomAirBasis.changes)
                  field(_roomHeight, strings.roomHeight, EngUnit.metre,
                      strings.hintRoomSide),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          EngineeringSection(
            title: strings.airBasis,
            children: [
              EngineeringChoice<RoomAirBasis>(
                value: _basis,
                options: [
                  (RoomAirBasis.changes, strings.byAirChanges),
                  (RoomAirBasis.people, strings.byPeople),
                  (RoomAirBasis.area, strings.byArea),
                ],
                onChanged: (value) => setState(() => _basis = value),
              ),
              const SizedBox(height: 12),
              EngineeringInputGrid(children: [
                if (_basis == RoomAirBasis.changes)
                  field(_ach, strings.airChanges, EngUnit.perHour,
                      strings.hintAirChanges),
                if (_basis == RoomAirBasis.people) ...[
                  field(_people, strings.peopleCount, EngUnit.person,
                      strings.hintPeopleCount),
                  field(_perPerson, strings.airPerPerson,
                      EngUnit.cubicMetrePerHour, strings.hintAirPerPerson),
                ],
                if (_basis == RoomAirBasis.area)
                  field(_perSquareMetre, strings.airPerSquareMetre,
                      EngUnit.cubicMetrePerHour, strings.hintAirPerSquareMetre),
              ]),
            ],
          ),
        ],
    };
  }
}
