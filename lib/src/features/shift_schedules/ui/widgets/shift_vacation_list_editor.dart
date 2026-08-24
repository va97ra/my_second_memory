import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'shift_vacation_editor_dialog.dart';
import 'shift_vacation_period_tile.dart';

/// Список отпусков графика с кнопкой добавления.
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
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vacations.isEmpty)
          Container(
            key: const ValueKey('shift_vacations_empty'),
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.beach_access_rounded,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.noVacations,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < vacations.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            ShiftVacationPeriodTile(
              vacation: vacations[index],
              locale: locale,
              onRemove: () => onRemove(vacations[index].id),
            ),
          ],
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            key: const ValueKey('add_shift_vacation'),
            onPressed: () => _add(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(strings.addVacation),
          ),
        ),
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
    // Лист редактора мог закрыться, пока был открыт диалог: тогда сообщать
    // о новом отпуске уже некому.
    if (vacation != null && context.mounted) {
      onAdd(vacation);
    }
  }
}
