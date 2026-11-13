import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/shift_schedule_color.dart';

/// График смен в шапке календаря: его цвет, название и рисунок.
class ShiftLegendChip extends StatelessWidget {
  const ShiftLegendChip({super.key, required this.schedule});

  final ShiftSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final color = shiftScheduleColor(AppThemeColors.of(context), schedule);
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(width: 8, height: 8),
            ),
            const SizedBox(width: 4),
            Text(
              schedule.organizationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
            ),
            const SizedBox(width: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                child: Text(
                  '${schedule.workDays}/${schedule.restDays}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
