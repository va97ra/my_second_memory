import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'engineering_helpers.dart';

/// Ответ закона Ома: значение, формула и подстановка в неё.
///
/// Формулу показывают вместе с числами нарочно: человек, который учится,
/// должен видеть, откуда взялся ответ, а не только сам ответ.
class OhmLawOutputPanel extends ConsumerWidget {
  const OhmLawOutputPanel({
    required this.unknown,
    required this.voltage,
    required this.current,
    required this.resistance,
    super.key,
  });

  final OhmLawUnknown unknown;
  final String voltage;
  final String current;
  final String resistance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    final voltageV = parseToolNumber(voltage);
    final currentA = parseToolNumber(current);
    final resistanceOhm = parseToolNumber(resistance);
    final problem = _problem(strings, voltageV, currentA, resistanceOhm);
    if (problem != null) {
      return ToolResultCard(
        value: '$problem — ${strings.invalidNumber.toLowerCase()}',
      );
    }
    final result = solveOhmLaw(
      unknown: unknown,
      voltageV: voltageV,
      currentA: currentA,
      resistanceOhm: resistanceOhm,
    );
    final u = formatEngValue(result.voltageV, EngUnit.volt, ru);
    final i = formatEngValue(result.currentA, EngUnit.ampere, ru);
    final r = formatEngValue(result.resistanceOhm, EngUnit.ohm, ru);
    final p = formatEngValue(result.powerW, EngUnit.watt, ru);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolResultCard(
          value: switch (unknown) {
            OhmLawUnknown.voltage => u,
            OhmLawUnknown.current => i,
            OhmLawUnknown.resistance => r,
          },
          details: [
            '${strings.formula}: ${_formula(unknown)}',
            switch (unknown) {
              OhmLawUnknown.voltage => '$u = $i × $r',
              OhmLawUnknown.current => '$i = $u / $r',
              OhmLawUnknown.resistance => '$r = $u / $i',
            },
            'P = U × I = $p',
            strings.ohmLawActiveLoadNote,
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => saveEngineering(
            context,
            ref,
            discipline: 'electrical',
            calculator: 'ohmLaw',
            values: {
              'voltageV': result.voltageV,
              'currentA': result.currentA,
              'resistanceOhm': result.resistanceOhm,
              'powerW': result.powerW,
            },
          ),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(strings.saveCalculation),
        ),
      ],
    );
  }

  String _formula(OhmLawUnknown unknown) => switch (unknown) {
        OhmLawUnknown.voltage => 'U = I × R',
        OhmLawUnknown.current => 'I = U / R',
        OhmLawUnknown.resistance => 'R = U / I',
      };

  /// Проверяются только те поля, которые участвуют в расчёте: искомой
  /// величины на экране нет, и требовать от неё числа незачем.
  String? _problem(
    AppStrings strings,
    double? voltageV,
    double? currentA,
    double? resistanceOhm,
  ) {
    if (unknown != OhmLawUnknown.voltage &&
        (voltageV == null || voltageV < 0)) {
      return strings.voltage;
    }
    if (unknown != OhmLawUnknown.current) {
      // Сопротивление ищут делением на ток — нулевой ток здесь не годится.
      final zeroForbidden = unknown == OhmLawUnknown.resistance;
      if (currentA == null || currentA < 0 || (zeroForbidden && currentA == 0)) {
        return strings.current;
      }
    }
    if (unknown != OhmLawUnknown.resistance &&
        (resistanceOhm == null || resistanceOhm <= 0)) {
      return strings.resistance;
    }
    return null;
  }
}
