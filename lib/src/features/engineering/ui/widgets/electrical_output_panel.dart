import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'electrical_mode.dart';
import 'engineering_helpers.dart';

class ElectricalOutputPanel extends ConsumerWidget {
  const ElectricalOutputPanel({
    required this.mode,
    this.voltage = '',
    this.current = '',
    this.factor = '',
    this.extra = '',
    this.section = '',
    this.loads = '',
    this.loadsController,
    this.onChanged,
    this.threePhase = false,
    this.copper = true,
    super.key,
  });

  final ElectricalMode mode;
  final String voltage, current, factor, extra, section, loads;
  final TextEditingController? loadsController;
  final VoidCallback? onChanged;
  final bool threePhase, copper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ru = AppStrings.of(context).isRu;
    if (mode == ElectricalMode.phases) return _phases(context, ref);
    final voltageV = parseToolNumber(voltage),
        currentA = parseToolNumber(current);
    final powerFactor = parseToolNumber(factor),
        extraValue = parseToolNumber(extra);
    try {
      if ([voltageV, currentA, powerFactor, extraValue].contains(null)) {
        throw const FormatException();
      }
      if (mode == ElectricalMode.power) {
        final result = threePhase
            ? EngineeringCalculations.threePhase(
                lineVoltageV: voltageV!,
                currentA: currentA!,
                powerFactor: powerFactor!,
                efficiency: extraValue!)
            : EngineeringCalculations.singlePhase(
                voltageV: voltageV!,
                currentA: currentA!,
                powerFactor: powerFactor!,
                efficiency: extraValue!);
        return _output(context, ref,
            '${formatToolNumber(result.activePowerW / 1000)} ${EngUnit.kilowatt.symbol(ru)}',
            'power', {
          'voltageV': voltageV,
          'currentA': currentA,
          'powerFactor': powerFactor,
          'efficiency': extraValue,
          'threePhase': threePhase ? 1 : 0,
        });
      }
      final sectionMm2 = parseToolNumber(section);
      if (sectionMm2 == null) throw const FormatException();
      final result = EngineeringCalculations.voltageDrop(
          currentA: currentA!,
          oneWayLengthM: extraValue!,
          sectionMm2: sectionMm2,
          voltageV: voltageV!,
          threePhase: threePhase,
          copper: copper,
          powerFactor: powerFactor!);
      return _output(
          context,
          ref,
          '${formatToolNumber(result.dropV)} ${EngUnit.volt.symbol(ru)}'
          ' · ${formatToolNumber(result.dropPercent)} %',
          'voltageDrop', {
        'voltageV': voltageV,
        'currentA': currentA,
        'powerFactor': powerFactor,
        'lengthM': extraValue,
        'sectionMm2': sectionMm2,
        'threePhase': threePhase ? 1 : 0,
        'copper': copper ? 1 : 0,
      },
          details: [
            '${AppStrings.of(context).loss}: '
                '${formatToolNumber(result.lossW)} ${EngUnit.watt.symbol(ru)}'
          ]);
    } catch (_) {
      return ToolResultCard(value: AppStrings.of(context).invalidNumber);
    }
  }

  Widget _phases(BuildContext context, WidgetRef ref) {
    final values = loads
        .split(RegExp(r'[,;\s]+'))
        .map(parseToolNumber)
        .whereType<double>()
        .toList();
    final phases = values.isEmpty
        ? const <double>[]
        : EngineeringCalculations.balancePhases(values);
    final strings = AppStrings.of(context);
    return Column(children: [
      TextField(
          controller: loadsController,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: strings.loadsSeparatedByCommas)),
      const SizedBox(height: 16),
      ToolResultCard(
          value: phases.isEmpty
              ? '—'
              : 'L1 ${formatToolNumber(phases[0])} ${EngUnit.watt.symbol(strings.isRu)}'
                  ' · L2 ${formatToolNumber(phases[1])} ${EngUnit.watt.symbol(strings.isRu)}'
                  ' · L3 ${formatToolNumber(phases[2])} ${EngUnit.watt.symbol(strings.isRu)}'),
      const SizedBox(height: 12),
      _saveButton(context, ref, phases.isEmpty ? null : 'phaseBalance',
          {for (var i = 0; i < values.length; i++) 'load$i': values[i]}),
    ]);
  }

  Widget _output(BuildContext context, WidgetRef ref, String value,
          String calculator, Map<String, double> values,
          {List<String> details = const []}) =>
      Column(children: [
        ToolResultCard(value: value, details: details),
        const SizedBox(height: 12),
        _saveButton(context, ref, calculator, values),
      ]);

  Widget _saveButton(BuildContext context, WidgetRef ref, String? calculator,
          Map<String, double> values) =>
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
            onPressed: calculator == null
                ? null
                : () => saveEngineering(context, ref,
                    discipline: 'electrical',
                    calculator: calculator,
                    values: values),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(AppStrings.of(context).saveCalculation)),
      );
}
