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
    this.loads = '',
    this.loadsController,
    this.onChanged,
    this.threePhase = false,
    super.key,
  });

  final ElectricalMode mode;
  final String voltage, current, factor, extra, loads;
  final TextEditingController? loadsController;
  final VoidCallback? onChanged;
  final bool threePhase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    if (mode == ElectricalMode.phases) return _phases(context, ref);
    final voltageV = parseToolNumber(voltage);
    final currentA = parseToolNumber(current);
    final powerFactor = parseToolNumber(factor);
    final efficiency = parseToolNumber(extra);
    final problem = _problem(strings, voltageV, currentA, powerFactor, efficiency);
    if (problem != null) {
      return ToolResultCard(
        value: '$problem — ${strings.invalidNumber.toLowerCase()}',
      );
    }
    final result = threePhase
        ? EngineeringCalculations.threePhase(
            lineVoltageV: voltageV!,
            currentA: currentA!,
            powerFactor: powerFactor!,
            efficiency: efficiency!,
          )
        : EngineeringCalculations.singlePhase(
            voltageV: voltageV!,
            currentA: currentA!,
            powerFactor: powerFactor!,
            efficiency: efficiency!,
          );
    return _output(
      context,
      ref,
      formatEngValue(result.activePowerW / 1000, EngUnit.kilowatt, strings.isRu),
      'power',
      {
        'voltageV': voltageV,
        'currentA': currentA,
        'powerFactor': powerFactor,
        'efficiency': efficiency,
        'threePhase': threePhase ? 1 : 0,
      },
    );
  }

  /// Первое поле, которое мешает посчитать, — сверху вниз, как на экране.
  ///
  /// Вместо `catch` вокруг расчёта: «введите корректное число» без имени поля
  /// одинаково выглядело и при пустой графе, и при ошибке в самом расчёте.
  String? _problem(
    AppStrings strings,
    double? voltageV,
    double? currentA,
    double? powerFactor,
    double? efficiency,
  ) {
    if (voltageV == null || voltageV <= 0) return strings.voltage;
    if (currentA == null || currentA < 0) return strings.loadCurrent;
    if (powerFactor == null || powerFactor <= 0 || powerFactor > 1) {
      return 'cos φ';
    }
    if (efficiency == null || efficiency <= 0 || efficiency > 1) {
      return strings.efficiency;
    }
    return null;
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
              : 'L1 ${formatEngValue(phases[0], EngUnit.watt, strings.isRu)}'
                  ' · L2 ${formatEngValue(phases[1], EngUnit.watt, strings.isRu)}'
                  ' · L3 ${formatEngValue(phases[2], EngUnit.watt, strings.isRu)}'),
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
