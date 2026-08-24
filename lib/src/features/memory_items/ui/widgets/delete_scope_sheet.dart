import 'package:flutter/material.dart';

/// Что именно удаляют, когда запись принадлежит серии.
enum MemoryDeleteScope { one, future, series }

/// Спрашивает область удаления. null — человек ушёл, не ответив.
Future<MemoryDeleteScope?> askDeleteScope(BuildContext context) {
  return showModalBottomSheet<MemoryDeleteScope>(
    context: context,
    showDragHandle: true,
    builder: (context) => const DeleteScopeSheet(),
  );
}

/// Выбор области удаления записи из серии.
class DeleteScopeSheet extends StatelessWidget {
  const DeleteScopeSheet({super.key});

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
              ru ? 'Удалить только эту запись' : 'Delete only this record',
            ),
            onTap: () => Navigator.of(context).pop(MemoryDeleteScope.one),
          ),
          ListTile(
            leading: const Icon(Icons.event_busy_rounded),
            title: Text(
              ru ? 'Удалить эту и будущие' : 'Delete this and future records',
            ),
            onTap: () => Navigator.of(context).pop(MemoryDeleteScope.future),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded),
            title: Text(
              ru ? 'Удалить всю серию' : 'Delete the entire series',
            ),
            onTap: () => Navigator.of(context).pop(MemoryDeleteScope.series),
          ),
        ],
      ),
    );
  }
}
