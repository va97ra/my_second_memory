import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'shift_schedule_tile_details.dart';

/// Карточка графика в списке: цвет, содержимое, переключатель и меню.
class ShiftScheduleTile extends StatelessWidget {
  const ShiftScheduleTile({
    super.key,
    required this.schedule,
    required this.locale,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final ShiftSchedule schedule;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final color = Color(schedule.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onEdit,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: schedule.isEnabled
                    ? color.withValues(alpha: 0.34)
                    : colors.outlineVariant,
              ),
              color: schedule.isEnabled
                  ? color.withValues(alpha: 0.1)
                  : colors.surface.withValues(alpha: 0.92),
              boxShadow: _shadow(context, color),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(width: 38, height: 38),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShiftScheduleTileDetails(
                      schedule: schedule,
                      locale: locale,
                    ),
                  ),
                  Switch(
                    value: schedule.isEnabled,
                    onChanged: (_) => onToggle(),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(strings.editShiftSchedule),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(strings.delete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Тень блокнотной темы, если она есть; иначе — своя, по цвету графика.
  List<BoxShadow> _shadow(BuildContext context, Color color) {
    final notebook = notebookSurfaceShadow(context, NotebookSurfaceDepth.card);
    if (notebook.isNotEmpty) return notebook;
    return [
      BoxShadow(
        color: color.withValues(alpha: schedule.isEnabled ? 0.1 : 0),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ];
  }
}
