import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/production_calendar_provider.dart';

import 'production_calendar_dialog.dart';

class ProductionDayStatus extends ConsumerWidget {
  const ProductionDayStatus({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final day =
        ref.watch(productionCalendarProvider(date.year)).calendar.day(date);
    return TextButton(
      onPressed: () => ProductionCalendarDialog.show(context, date),
      child: Text(
        '${strings.productionDayLabel(day?.name)} · ${strings.isRu ? 'РФ, 5/2' : 'RU, 5/2'}',
        textAlign: TextAlign.center,
      ),
    );
  }
}
