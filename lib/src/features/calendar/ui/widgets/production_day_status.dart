import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'production_calendar_dialog.dart';

class ProductionDayStatus extends ConsumerWidget {
  const ProductionDayStatus({super.key, required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      NotebookPaperIsland(child: Builder(builder: _content));

  Widget _content(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: NotebookCardSurface(
          child: TextButton(
        key: const ValueKey('production_day_summary'),
        onPressed: () => ProductionCalendarDialog.show(context, date),
        style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: Theme.of(context).colorScheme.onSurface),
        child: Row(children: [
          const Icon(Icons.calendar_month_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(strings.productionStatistics,
                  style: Theme.of(context).textTheme.labelLarge)),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ]),
      )),
    );
  }
}
