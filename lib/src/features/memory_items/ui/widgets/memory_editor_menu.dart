import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Что можно сделать с записью из меню редактора.
enum MemoryEditorAction {
  date,
  time,
  clearTime,
  reminder,
  repeat,
  duplicate,
  applyToFuture,
  delete,
}

/// Меню редактора: когда запись стоит, как повторяется и что с ней делать.
///
/// Дата и время живут здесь, а не строкой на экране: со шкалы дня они уже
/// проставлены, а править их нужно редко.
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
    required this.dateText,
    required this.timeText,
    required this.reminderEnabled,
    required this.showDateAndTime,
    required this.onSelected,
  });

  final bool isUndated;
  final bool hasItem;
  final bool hasSeries;
  final bool hasRecurrence;

  /// Дата и время показываются прямо в пунктах: иначе, спрятав панель, мы
  /// спрятали бы и то, на какое число запись стоит.
  final String dateText;
  final String? timeText;

  /// Колокольчик на пункте времени: раньше он висел значком на плашке, и без
  /// него не видно, что напоминание вообще заведено.
  final bool reminderEnabled;

  /// Показывать ли дату и время в меню.
  ///
  /// У записи с календаря они выбраны рамкой на шкале дня, и повторять их
  /// здесь незачем. Выключатель оставлен, чтобы вернуть их там, где рамки
  /// нет и время задать больше нечем.
  final bool showDateAndTime;

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
              ? 'Когда и что с записью'
              : 'When and what to do',
      iconSize: 22,
      padding: const EdgeInsets.all(9),
      icon: Icon(
        Icons.settings_rounded,
        color: hasRecurrence
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (!isUndated && showDateAndTime) ...[
          _item(
            value: MemoryEditorAction.date,
            icon: Icons.event_rounded,
            title: '${strings.date}: $dateText',
          ),
          _item(
            value: MemoryEditorAction.time,
            icon: reminderEnabled
                ? Icons.notifications_active_rounded
                : Icons.schedule_rounded,
            title: '${strings.time}: ${timeText ?? strings.timeNotSet}',
          ),
          if (timeText != null)
            _item(
              value: MemoryEditorAction.clearTime,
              icon: Icons.timer_off_rounded,
              title: ru ? 'Убрать время' : 'Clear time',
            ),
        ],
        // Напоминание живёт отдельным пунктом, а не внутри времени: время
        // выбирают рамкой на шкале, а напомнить о деле нужно всё равно.
        if (!isUndated)
          _item(
            value: MemoryEditorAction.reminder,
            icon: reminderEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            title: ru ? 'Напоминание' : 'Reminder',
          ),
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
