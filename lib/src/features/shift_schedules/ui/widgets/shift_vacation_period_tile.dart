import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Один отпуск в списке: даты, длительность и кнопка удаления.
class ShiftVacationPeriodTile extends StatelessWidget {
  const ShiftVacationPeriodTile({
    super.key,
    required this.vacation,
    required this.locale,
    required this.onRemove,
  });

  final ShiftVacation vacation;
  final String locale;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final start = DateFormat.yMMMd(locale).format(vacation.startDate);
    final end = DateFormat.yMMMd(locale).format(vacation.endDate);

    return Container(
      key: ValueKey('shift_vacation_${vacation.id}'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF891C37),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD6A84B)),
            ),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.beach_access_rounded,
                size: 20,
                color: Color(0xFFFFE5A3),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$start — $end',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.vacationDays(vacation.durationDays),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('remove_shift_vacation_${vacation.id}'),
            tooltip: strings.delete,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
