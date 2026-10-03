import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/production_period_provider.dart';
import 'production_calendar_dialog.dart';

class ProductionMonthProgress extends ConsumerWidget {
  const ProductionMonthProgress({super.key, required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final rows = ref.watch(productionPeriodProvider(
        (date: month, period: ProductionPeriod.month)));
    if (rows.isEmpty) return const SizedBox.shrink();
    final progress = rows.first.progress;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
          onTap: () => ProductionCalendarDialog.show(context, month),
          child: Text(
            rows.length > 1
                ? strings.productionStatistics
                : progress == null
                    ? strings.productionUnknown
                    : strings.productionProgress(
                        progress.elapsed, progress.total, progress.remaining,
                        source: rows.first.name),
            key: const ValueKey('production_month_progress'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          )),
    );
  }
}
