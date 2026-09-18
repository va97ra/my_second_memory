import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../state/production_calendar_provider.dart';
import '../../../../navigation/page_turn_navigation.dart';
import '../../state/production_preferences.dart';
import 'production_month_progress.dart';

/// Month totals are read on demand, without taking space from the grid.
class ProductionCalendarDialog extends ConsumerWidget {
  const ProductionCalendarDialog({super.key, required this.month});
  final DateTime month;

  static Future<void> show(BuildContext context, DateTime month) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (_) => ProductionCalendarDialog(month: month),
    );
    if (openSettings == true && context.mounted) {
      await context.pageTurnPush('/calendar/preferences');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final state = ref.watch(productionCalendarProvider(month.year));
    final totals = state.calendar.month(month);
    return AlertDialog(
      scrollable: true,
      title: Text(strings.productionCalendar),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (ref.watch(productionPreferencesProvider).showProgress) ...[
            ProductionMonthProgress(month: month),
            Text(strings.productionProgressHint,
                style: Theme.of(context).textTheme.bodySmall),
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
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.settings)),
        TextButton(
          onPressed: state.loading
              ? null
              : () => ref
                  .read(productionCalendarProvider(month.year).notifier)
                  .refresh(),
          child: Text(strings.productionRefresh),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
