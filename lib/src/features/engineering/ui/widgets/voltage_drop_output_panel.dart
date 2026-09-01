import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/voltage_drop_query.dart';
import 'engineering_helpers.dart';
import 'voltage_drop_conductor_card.dart';

/// Ответ расчёта: сперва вердикт, потом числа, из которых он получен.
///
/// Электрику нужен ответ «проходит или нет», а не шесть знаков после запятой:
/// проценты и вольты стоят под вердиктом и объясняют его.
class VoltageDropOutputPanel extends ConsumerWidget {
  const VoltageDropOutputPanel({required this.input, super.key});

  final VoltageDropInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final query = input;
    if (query is VoltageDropProblem) {
      return Card(
        margin: EdgeInsets.zero,
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${query.field} — ${strings.invalidNumber.toLowerCase()}',
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
        ),
      );
    }
    query as VoltageDropQuery;
    final result = query.result;
    final passes = result.withinLimit(query.limitPercent);
    final minimum = query.minimumSectionMm2;
    final ru = strings.isRu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _verdict(context, strings, result.hot, passes, query.limitPercent),
        const SizedBox(height: 8),
        VoltageDropConductorCard(
          title: strings.conductorUnderLoad,
          state: result.hot,
          emphasised: true,
        ),
        const SizedBox(height: 8),
        VoltageDropConductorCard(
          title: strings.conductorCold,
          state: result.cold,
        ),
        const SizedBox(height: 8),
        Text(
          minimum == null
              ? strings.noSectionFitsLimit
              : '${strings.minimumSectionForLimit}:'
                  ' ${formatEngValue(minimum, EngUnit.millimetreSquared, ru)}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => saveEngineering(
            context,
            ref,
            discipline: 'electrical',
            calculator: 'voltageDrop',
            values: query.savedValues,
          ),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(strings.saveCalculation),
        ),
      ],
    );
  }

  Widget _verdict(
    BuildContext context,
    AppStrings strings,
    ConductorState hot,
    bool passes,
    double limitPercent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final ink = passes ? scheme.onTertiaryContainer : scheme.onErrorContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: passes ? scheme.tertiaryContainer : scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passes ? Icons.check_circle_outline : Icons.error_outline,
            color: ink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passes ? strings.withinDropLimit : strings.overDropLimit,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: ink),
                ),
                SelectableText(
                  '${formatToolNumber(hot.dropPercent, precision: 2)} %',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: ink),
                ),
                Text(
                  '${strings.dropLimitSection}:'
                  ' ${formatToolNumber(limitPercent, precision: 1)} %',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
