import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Плашки графиков, у которых этот день рабочий.
class WorkingShiftChips extends StatelessWidget {
  const WorkingShiftChips({
    super.key,
    required this.schedules,
    required this.date,
  });

  final List<ShiftSchedule> schedules;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final schedule in schedules) _chip(context, schedule),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, ShiftSchedule schedule) {
    final strings = AppStrings.of(context);
    final color = Color(schedule.colorValue);
    // Рабочий день, попавший в отпуск, так и подписан: график его считает
    // рабочим, но человек в этот день не работает.
    final label = schedule.isVacationWorkday(date)
        ? strings.vacation
        : strings.workingToday;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(width: 10, height: 10),
            ),
            const SizedBox(width: 7),
            Text(
              '$label: ${schedule.organizationName}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
