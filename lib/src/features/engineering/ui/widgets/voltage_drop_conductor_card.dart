import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Линия при одной температуре жилы: падение в вольтах, в процентах и потери.
///
/// Карточек две — холодная жила и нагретая. Разница между ними и есть вклад
/// нагрева, ради которого показаны обе.
class VoltageDropConductorCard extends StatelessWidget {
  const VoltageDropConductorCard({
    required this.title,
    required this.state,
    this.emphasised = false,
    super.key,
  });

  final String title;
  final ConductorState state;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    return Card(
      margin: EdgeInsets.zero,
      elevation: emphasised ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${title.toUpperCase()},'
              ' ${formatToolNumber(state.temperatureC, precision: 1)}'
              ' ${EngUnit.celsius.symbol(ru)}',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _stat(
                  theme,
                  strings.voltageDrop,
                  formatEngValue(state.dropV, EngUnit.volt, ru),
                ),
                _stat(
                  theme,
                  '%',
                  formatToolNumber(state.dropPercent, precision: 2),
                ),
                _stat(
                  theme,
                  strings.loss,
                  formatEngValue(state.lossW, EngUnit.watt, ru),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(ThemeData theme, String caption, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      );
}
