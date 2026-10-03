import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

class ProductionProgressNumbers extends StatelessWidget {
  const ProductionProgressNumbers({super.key, required this.progress});
  final ProductionProgress progress;
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 24, runSpacing: 12, children: [
        for (final entry in {
          strings.productionElapsed: progress.elapsed,
          strings.productionRemaining: progress.remaining,
          strings.productionTotal: progress.total
        }.entries)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${entry.value}',
                style: text.headlineSmall?.copyWith(
                    fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
            Text(entry.key, style: text.labelMedium),
          ]),
      ]),
      const SizedBox(height: 12),
      Semantics(
          label:
              '${strings.productionElapsed}: ${progress.elapsed}, ${strings.productionTotal}: ${progress.total}',
          child: LinearProgressIndicator(
              value:
                  progress.total == 0 ? 0 : progress.elapsed / progress.total,
              minHeight: 4)),
    ]);
  }
}
