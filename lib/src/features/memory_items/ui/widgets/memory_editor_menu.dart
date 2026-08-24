import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Что можно сделать с записью из меню редактора.
enum MemoryEditorAction { repeat, duplicate, applyToFuture, delete }

/// Меню редактора: повтор, дублирование, применение к будущим и удаление.
///
/// Состав зависит от записи: у записки нет ни дат, ни серии, поэтому ей
/// остаётся только удаление.
class MemoryEditorMenu extends StatelessWidget {
  const MemoryEditorMenu({
    super.key,
    required this.isUndated,
    required this.hasItem,
    required this.hasSeries,
    required this.hasRecurrence,
    required this.onSelected,
  });

  final bool isUndated;
  final bool hasItem;
  final bool hasSeries;
  final bool hasRecurrence;
  final ValueChanged<MemoryEditorAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = Localizations.localeOf(context).languageCode == 'ru';

    return PopupMenuButton<MemoryEditorAction>(
      key: const ValueKey('memory_editor_menu'),
      tooltip: isUndated
          ? strings.delete
          : ru
              ? 'Повтор и действия'
              : 'Repeat and actions',
      iconSize: 22,
      padding: const EdgeInsets.all(9),
      icon: Icon(
        isUndated ? Icons.more_vert_rounded : Icons.event_repeat_rounded,
        color: hasRecurrence
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (!isUndated)
          _item(
            value: MemoryEditorAction.repeat,
            icon: Icons.event_repeat_rounded,
            title: ru ? 'Настроить повтор' : 'Set recurrence',
          ),
        if (!isUndated && hasItem)
          _item(
            value: MemoryEditorAction.duplicate,
            icon: Icons.content_copy_rounded,
            title: ru ? 'Дублировать на даты' : 'Duplicate to dates',
          ),
        if (!isUndated && hasSeries)
          _item(
            value: MemoryEditorAction.applyToFuture,
            icon: Icons.update_rounded,
            title: ru ? 'Применить к будущим' : 'Apply to future',
          ),
        if (hasItem)
          _item(
            value: MemoryEditorAction.delete,
            icon: Icons.delete_rounded,
            title: strings.delete,
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }

  PopupMenuItem<MemoryEditorAction> _item({
    required MemoryEditorAction value,
    required IconData icon,
    required String title,
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(title),
      ),
    );
  }
}
