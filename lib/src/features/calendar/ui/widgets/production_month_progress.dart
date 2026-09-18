import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/production_progress_provider.dart';

class ProductionMonthProgress extends ConsumerWidget {
  const ProductionMonthProgress({super.key, required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final progress = ref.watch(productionProgressProvider(month));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        progress == null
            ? strings.productionUnknown
            : strings.productionProgress(
                progress.elapsed, progress.total, progress.remaining),
        key: const ValueKey('production_month_progress'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
