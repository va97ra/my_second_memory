import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../state/production_calendar_provider.dart';

class ProductionCalendarDetails extends ConsumerWidget {
  const ProductionCalendarDetails({super.key, required this.month});
  final DateTime month;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final state = ref.watch(productionCalendarProvider(month.year));
    final totals = state.calendar.month(month);
    return ExpansionTile(
        title: Text(strings.productionDetails),
        tilePadding: EdgeInsets.zero,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat.yMMMM(locale).format(month),
                style: Theme.of(context).textTheme.titleMedium),
            Text(strings.productionScope),
            const SizedBox(height: 16),
            if (totals == null)
              Text(strings.productionUnknown)
            else ...[
              Text(strings.productionTotals(
                  totals.workingDays, totals.daysOff, totals.shortenedDays)),
              const SizedBox(height: 16),
              for (final week in [40, 36, 24])
                Text(strings.productionHours(week,
                    NumberFormat('0.#', locale).format(totals.hours(week)))),
            ],
            const SizedBox(height: 16),
            Text(strings.productionLegend),
            if (month.year == 2026 && totals != null) ...[
              const SizedBox(height: 16),
              Text(strings.productionSource,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            if (totals != null)
              Text(
                  state.cached == null
                      ? strings.productionBundled
                      : strings.productionApiSource,
                  style: Theme.of(context).textTheme.bodySmall),
            if (state.cached != null)
              Text(
                  strings.productionChecked(DateFormat.yMd(locale)
                      .add_Hm()
                      .format(state.cached!.checkedAt.toLocal())),
                  style: Theme.of(context).textTheme.bodySmall),
            if (state.loading) Text(strings.productionUpdating),
            if (state.failed) Text(strings.productionUpdateFailed),
            TextButton(
                onPressed: state.loading
                    ? null
                    : () => ref
                        .read(productionCalendarProvider(month.year).notifier)
                        .refresh(),
                child: Text(strings.productionRefresh)),
          ])
        ]);
  }
}
