import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'metadata_action.dart';
import 'metadata_divider.dart';
import 'type_picker_row.dart';

/// Панель метаданных записи: дата, время, напоминание, повтор.
class EditorMetadataBar extends StatelessWidget {
  const EditorMetadataBar({super.key, 
    required this.selectedType,
    required this.dateText,
    required this.timeText,
    required this.reminderEnabled,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onClearTime,
    required this.onTypeChanged,
  });

  final MemoryType selectedType;
  final String dateText;
  final String? timeText;
  final bool reminderEnabled;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback? onClearTime;
  final ValueChanged<MemoryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final typeColor = memoryTypeColor(selectedType);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4F35).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: MetadataAction(
                key: const ValueKey('memory_type_picker'),
                icon: memoryTypeIcon(selectedType),
                label: strings.recordType,
                value: selectedType.label(locale),
                color: typeColor,
                onTap: () => _showTypePicker(context),
              ),
            ),
            const MetadataDivider(),
            Expanded(
              flex: 10,
              child: MetadataAction(
                key: const ValueKey('memory_date_picker'),
                icon: Icons.event_rounded,
                label: strings.date,
                value: dateText,
                color: const Color(0xFFC98A70),
                onTap: onDateTap,
              ),
            ),
            const MetadataDivider(),
            Expanded(
              flex: 9,
              child: MetadataAction(
                key: const ValueKey('memory_time_picker'),
                icon: Icons.schedule_rounded,
                label: strings.time,
                value: timeText ?? strings.timeNotSet,
                isPlaceholder: timeText == null,
                color: const Color(0xFFC98A70),
                onTap: onTimeTap,
                onClear: onClearTime,
                badgeIcon:
                    reminderEnabled ? Icons.notifications_active_rounded : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTypePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<MemoryType>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final locale = Localizations.localeOf(context).languageCode;
        final strings = AppStrings.of(context);

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text(
                  strings.recordType,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              for (final type in editableMemoryTypes)
                TypePickerRow(
                  type: type,
                  label: type.label(locale),
                  selected: type == selectedType,
                  onTap: () => Navigator.of(context).pop(type),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onTypeChanged(selected);
    }
  }
}
