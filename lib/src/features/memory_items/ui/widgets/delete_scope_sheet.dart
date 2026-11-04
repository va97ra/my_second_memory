import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/memory_item_commands.dart';

/// Что именно удаляют, когда запись принадлежит серии.

/// Спрашивает область удаления. null — человек ушёл, не ответив.
/// Спрашивает, удалять ли запись и какую часть серии. Null — передумали.
Future<MemoryDeleteScope?> askMemoryDelete(
  BuildContext context,
  MemoryItem item,
) async {
  final scope = item.seriesId == null
      ? MemoryDeleteScope.one
      : await askDeleteScope(context);
  if (scope == null || !context.mounted) return null;

  final strings = AppStrings.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(strings.deleteRecordQuestion),
      content: Text(item.title),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.delete),
        ),
      ],
    ),
  );
  return confirmed == true ? scope : null;
}

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
