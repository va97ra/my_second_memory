import 'package:flutter/material.dart';

/// Спрашивает, правится одно вхождение серии или все будущие.
///
/// true — эта и будущие записи, false — только эта, null — человек ушёл, не
/// ответив.
Future<bool?> askEditScope(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => const EditScopeSheet(),
  );
}

/// Выбор области правки записи из серии.
class EditScopeSheet extends StatelessWidget {
  const EditScopeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.event_note_rounded),
            title: Text(
              ru ? 'Редактировать только эту запись' : 'Edit only this record',
            ),
            onTap: () => Navigator.of(context).pop(false),
          ),
          ListTile(
            leading: const Icon(Icons.event_repeat_rounded),
            title: Text(
              ru ? 'Эту и будущие записи' : 'This and future records',
            ),
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
