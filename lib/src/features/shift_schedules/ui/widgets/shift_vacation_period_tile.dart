import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'shift_editor_row.dart';

/// Один отпуск в списке: даты, длительность и удаление.
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
    final format = DateFormat.MMMd(locale);

    return ShiftEditorRow(
      key: ValueKey('shift_vacation_${vacation.id}'),
      icon: Icons.beach_access_rounded,
      color: AppPalette.vacationCloth,
      title:
          '${format.format(vacation.startDate)} — ${format.format(vacation.endDate)}',
      subtitle: strings.vacationDays(vacation.durationDays),
      trailing: Tooltip(
        message: strings.delete,
        child: NotebookPressable(
          key: ValueKey('remove_shift_vacation_${vacation.id}'),
          onTap: onRemove,
          child: SizedBox(
            width: 40,
            height: 44,
            child: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
