import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'shift_editor_row.dart';
import 'shift_vacation_editor_dialog.dart';
import 'shift_vacation_period_tile.dart';

/// Список отпусков графика со строкой добавления.
class ShiftVacationListEditor extends StatelessWidget {
  const ShiftVacationListEditor({
    super.key,
    required this.vacations,
    required this.locale,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ShiftVacation> vacations;
  final String locale;
  final ValueChanged<ShiftVacation> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final vacation in vacations)
          ShiftVacationPeriodTile(
            vacation: vacation,
            locale: locale,
            onRemove: () => onRemove(vacation.id),
          ),
        ShiftEditorRow(
          key: const ValueKey('add_shift_vacation'),
          icon: Icons.add_rounded,
          color: Theme.of(context).colorScheme.primary,
          title: strings.addVacation,
          subtitle: vacations.isEmpty ? strings.noVacations : null,
          onTap: () => _add(context),
        ),
        if (vacations.isEmpty)
          const SizedBox.shrink(key: ValueKey('shift_vacations_empty')),
      ],
    );
  }

  /// Новый отпуск набирается в диалоге и приходит уже проверенным на
  /// пересечение с уже существующими.
  Future<void> _add(BuildContext context) async {
    final vacation = await showDialog<ShiftVacation>(
      context: context,
      builder: (context) =>
          ShiftVacationEditorDialog(existingVacations: vacations),
    );
    // Редактор мог закрыться, пока был открыт диалог: тогда сообщать
    // о новом отпуске уже некому.
    if (vacation != null && context.mounted) {
      onAdd(vacation);
    }
  }
}
