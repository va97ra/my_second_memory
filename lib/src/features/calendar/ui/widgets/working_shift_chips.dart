import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/day_shift_progress_provider.dart';
import '../../../shift_schedules/shift_schedules.dart';

/// Bounded scrolling leaves room for the day timeline even with many shifts.
class WorkingShiftChips extends ConsumerWidget {
  const WorkingShiftChips({super.key, required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final shifts = ref.watch(dayShiftProgressProvider(date));
    final hasSchedules =
        ref.watch(shiftSchedulesControllerProvider).any((s) => s.isEnabled);
    if (!hasSchedules) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (shifts.isEmpty)
            Text(strings.shiftDayOff, textAlign: TextAlign.center),
          for (final shift in shifts)
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Color(shift.schedule.colorValue)
                          .withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Color(shift.schedule.colorValue)
                              .withValues(alpha: .34))),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 7),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shift.schedule.organizationName,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            Text(shift.vacation
                                ? strings.shiftVacationDay
                                : strings.shiftOrdinal(
                                    shift.progress.elapsed + 1,
                                    shift.progress.total)),
                            Text(
                                strings.shiftDayProgress(
                                    shift.progress.elapsed,
                                    shift.progress.remaining -
                                        (shift.vacation ? 0 : 1)),
                                style: Theme.of(context).textTheme.bodySmall),
                          ])),
                )),
        ]),
      ),
    );
  }
}
