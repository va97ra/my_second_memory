import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/screen_chrome.dart';
import '../../state/memory_editor_controller.dart';
import 'memory_autosave_badge.dart';
import 'memory_editor_menu.dart';

/// Шапка редактора: что правят, как идёт сохранение и меню записи.
class MemoryEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MemoryEditorAppBar({
    super.key,
    required this.controller,
    required this.item,
    required this.onBack,
    required this.onAction,
  });

  final MemoryEditorController controller;

  /// Запись, которую правят, или null у ещё не сохранённого черновика.
  final MemoryItem? item;

  final VoidCallback onBack;
  final ValueChanged<MemoryEditorAction> onAction;

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
            memorySaveStatusLabel(
              context,
              isSaving: isSaving,
              hasError: hasSaveError,
            ),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: hasSaveError
                      ? colors.error
                      : isSaving
                          ? const Color(0xFF9A6A32)
                          : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
      actions: [
        MemoryAutosaveBadge(isSaving: isSaving, hasError: hasSaveError),
        // У новой записки нечего ни повторять, ни удалять: меню ей незачем.
        if (!isUndated || hasItem)
          MemoryEditorMenu(
            isUndated: isUndated,
            hasItem: hasItem,
            hasSeries: item?.seriesId != null,
            hasRecurrence: controller.form.recurrenceFrequency != null,
            onSelected: onAction,
          ),
      ],
    );
  }

  String _title(AppStrings strings) {
    if (isUndated) return hasItem ? strings.editNote : strings.newNote;
    return hasItem ? strings.editRecord : strings.newRecord;
  }
}
