import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../navigation/page_turn_navigation.dart';
import '../../state/production_period_provider.dart';
import '../../state/production_preferences.dart';
import 'production_calendar_details.dart';
import 'production_progress_numbers.dart';
import 'working_shift_chips.dart';

class ProductionCalendarDialog extends ConsumerStatefulWidget {
  const ProductionCalendarDialog({super.key, required this.month});
  final DateTime month;
  static Future<void> show(BuildContext context, DateTime month) async {
    final settings = await showDialog<bool>(
        context: context,
        builder: (_) => ProductionCalendarDialog(month: month));
    if (settings == true && context.mounted) {
      await context.pageTurnPush('/calendar/preferences');
    }
  }

  @override
  ConsumerState<ProductionCalendarDialog> createState() =>
      _ProductionCalendarDialogState();
}

class _ProductionCalendarDialogState
    extends ConsumerState<ProductionCalendarDialog> {
  ProductionPeriod period = ProductionPeriod.month;
  @override
  Widget build(BuildContext context) =>
      NotebookPaperIsland(child: Builder(builder: _content));

  Widget _content(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final rows = ref
        .watch(productionPeriodProvider((date: widget.month, period: period)));
    final prefs = ref.watch(productionPreferencesProvider);
    final text = Theme.of(context).textTheme;
    final date = widget.month;
    final monday = DateTime(date.year, date.month, date.day - date.weekday + 1);
    final range = switch (period) {
      ProductionPeriod.week =>
        '${DateFormat.yMMMd(locale).format(monday)} — ${DateFormat.yMMMd(locale).format(monday.add(const Duration(days: 6)))}',
      ProductionPeriod.month => DateFormat.yMMMM(locale).format(date),
      ProductionPeriod.year => '${date.year}',
    };
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: NotebookCardSurface(
          padding: const EdgeInsets.all(16),
          child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                style: text.bodyMedium!.copyWith(fontFamily: 'Manrope'),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Row(children: [
                        Expanded(
                            child: Text(strings.productionStatistics,
                                style: text.titleMedium)),
                        IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .closeButtonLabel,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded))
                      ]),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        for (final p in ProductionPeriod.values)
                          ChoiceChip(
                              key: ValueKey('production_period_${p.name}'),
                              label: Text(switch (p) {
                                ProductionPeriod.week => strings.productionWeek,
                                ProductionPeriod.month =>
                                  strings.productionMonth,
                                ProductionPeriod.year => strings.productionYear
                              }),
                              selected: period == p,
                              onSelected: (_) => setState(() => period = p)),
                      ]),
                      const SizedBox(height: 16),
                      Text(range, style: text.titleSmall),
                      const SizedBox(height: 4),
                      if (rows.isEmpty) Text(strings.productionChooseSource),
                      for (final row in rows) ...[
                        const SizedBox(height: 16),
                        Text(row.name, style: text.titleSmall),
                        const SizedBox(height: 8),
                        if (row.progress != null)
                          ProductionProgressNumbers(progress: row.progress!),
                      ],
                      const SizedBox(height: 16),
                      Text(strings.productionPlanNote, style: text.bodySmall),
                      Text(
                          prefs.includeToday
                              ? strings.productionTodayIncluded
                              : strings.productionTodayExcluded,
                          style: text.bodySmall),
                      if (rows.isNotEmpty)
                        ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(DateFormat.yMMMEd(locale).format(date),
                                style: text.bodyMedium),
                            children: [WorkingShiftChips(date: date)]),
                      ProductionCalendarDetails(month: widget.month),
                      const SizedBox(height: 8),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(true),
                              icon: const Icon(Icons.tune_rounded),
                              label: Text(strings.settings))),
                    ])),
              )),
        ),
      ),
    );
  }
}
