import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/screen_chrome.dart';
import '../../state/memory_editor_controller.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'memory_editor_menu.dart';
import 'memory_save_status.dart';
import 'type_picker_sheet.dart';

/// Шапка редактора: что правят, как идёт сохранение и меню записи.
class MemoryEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MemoryEditorAppBar({
    super.key,
    required this.controller,
    required this.item,
    required this.onBack,
    required this.onAction,
    required this.dateText,
    required this.timeText,
    required this.reminderEnabled,
    required this.showDateAndTime,
    required this.onTypeChanged,
  });

  final MemoryEditorController controller;

  /// Запись, которую правят, или null у ещё не сохранённого черновика.
  final MemoryItem? item;

  final VoidCallback onBack;
  final ValueChanged<MemoryEditorAction> onAction;

  /// Показываются в пунктах меню: панели с датой и временем больше нет.
  final String dateText;
  final String? timeText;
  final bool reminderEnabled;

  /// См. [MemoryEditorMenu.showDateAndTime].
  final bool showDateAndTime;

  final ValueChanged<MemoryType> onTypeChanged;

  bool get isUndated => controller.form.isUndated;
  bool get hasItem => item != null;

  /// Та же высота, что у всех шапок приложения.
  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final isSaving = controller.isSaving;
    final hasSaveError = controller.hasSaveError;

    return AppPageAppBar(
      onBack: onBack,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title(strings),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            key: const ValueKey('memory_save_status'),
            memorySaveStatusLabel(
              context,
              isSaving: isSaving,
              hasError: hasSaveError,
            ),
            // Цветом говорит сама подпись, отдельного значка ей не нужно:
            // сохранено — зелёная, ещё нет — обычная, сорвалось — красная.
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: hasSaveError
                      ? colors.error
                      : isSaving
                          ? colors.onSurface
                          : const Color(0xFF168653),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
      actions: [
        // Вид записи — кнопкой, а не строкой формы: он у записи один и
        // меняется редко, а место занимал постоянно. У записки вид тоже
        // есть и виден в ленте, поэтому кнопка нужна и ей.
        IconButton(
            key: const ValueKey('memory_type_picker'),
            tooltip: strings.recordType,
            iconSize: 22,
            padding: const EdgeInsets.all(9),
            constraints: const BoxConstraints(),
            onPressed: () => _pickType(context),
          icon: Icon(
            memoryTypeIcon(controller.form.type),
            color: memoryTypeColor(controller.form.type),
          ),
        ),
        // У новой записки нечего ни повторять, ни удалять: меню ей незачем.
        if (!isUndated || hasItem)
          MemoryEditorMenu(
            isUndated: isUndated,
            hasItem: hasItem,
            hasSeries: item?.seriesId != null,
            hasRecurrence: controller.form.recurrenceFrequency != null,
            dateText: dateText,
            timeText: timeText,
            reminderEnabled: reminderEnabled,
            showDateAndTime: showDateAndTime,
            onSelected: onAction,
          ),
      ],
    );
  }

  Future<void> _pickType(BuildContext context) async {
    final selected = await showMemoryTypePicker(
      context,
      selected: controller.form.type,
    );
    if (selected != null) onTypeChanged(selected);
  }

  String _title(AppStrings strings) {
    if (isUndated) return hasItem ? strings.editNote : strings.newNote;
    return hasItem ? strings.editRecord : strings.newRecord;
  }
}
