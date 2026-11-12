import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/memory_item_commands.dart';
import 'scope_choice_sheet.dart';

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

/// Какую часть серии удалить.
Future<MemoryDeleteScope?> askDeleteScope(BuildContext context) {
  final ru = Localizations.localeOf(context).languageCode == 'ru';
  return askScopeChoice(context, [
    ScopeChoice(
      icon: Icons.event_note_rounded,
      label: ru ? 'Удалить только эту запись' : 'Delete only this record',
      value: MemoryDeleteScope.one,
    ),
    ScopeChoice(
      icon: Icons.event_busy_rounded,
      label: ru ? 'Удалить эту и будущие' : 'Delete this and future records',
      value: MemoryDeleteScope.future,
    ),
    ScopeChoice(
      icon: Icons.delete_sweep_rounded,
      label: ru ? 'Удалить всю серию' : 'Delete the entire series',
      value: MemoryDeleteScope.series,
    ),
  ]);
}
