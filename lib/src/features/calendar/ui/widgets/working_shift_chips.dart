import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/day_shift_progress_provider.dart';

/// Details of the opened date, revealed inside the statistics dialog.
class WorkingShiftChips extends ConsumerWidget {
  const WorkingShiftChips({super.key, required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final shifts = ref.watch(dayShiftProgressProvider(date));
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (shifts.isEmpty) Text(strings.shiftDayOff, style: text.bodyMedium),
      for (final shift in shifts)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shift.schedule.organizationName, style: text.titleSmall),
              Text(
                  shift.vacation
                      ? strings.shiftVacationDay
                      : strings.shiftOrdinal(
                          shift.progress.elapsed + 1, shift.progress.total),
                  style: text.bodyMedium),
              Text(
                  strings.shiftDayProgress(shift.progress.elapsed,
                      shift.progress.remaining - (shift.vacation ? 0 : 1)),
                  style: text.bodySmall),
            ])),
    ]);
  }
}
