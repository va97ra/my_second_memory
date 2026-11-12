import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

enum _ShiftAction { edit, delete }

/// Что можно сделать с графиком: то же нижнее меню, что у записей.
Future<void> showShiftScheduleMenu(
  BuildContext context, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) async {
  final strings = AppStrings.of(context);
  final action = await showModalBottomSheet<_ShiftAction>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const ValueKey('shift_schedule_menu_edit'),
            leading: const Icon(Icons.edit_rounded),
            title: Text(strings.editShiftSchedule),
            onTap: () => Navigator.of(sheet).pop(_ShiftAction.edit),
          ),
          ListTile(
            key: const ValueKey('shift_schedule_menu_delete'),
            leading: const Icon(Icons.delete_rounded),
            title: Text(strings.delete),
            onTap: () => Navigator.of(sheet).pop(_ShiftAction.delete),
          ),
        ],
      ),
    ),
  );
  switch (action) {
    case _ShiftAction.edit:
      onEdit();
    case _ShiftAction.delete:
      onDelete();
    case null:
      break;
  }
}
