import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'editor_metadata_bar.dart';
import 'recurrence_hint.dart';

/// Содержимое редактора: поле записи, метаданные и особые поля вида.
class EditorBody extends StatelessWidget {
  const EditorBody({super.key, 
    required this.isUndated,
    required this.selectedType,
    required this.dateText,
    required this.timeText,
    required this.reminderEnabled,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onClearTime,
    required this.onTypeChanged,
    required this.specialFields,
    required this.showRecurrenceHint,
    required this.onRecurrenceHintTap,
    required this.recordEditor,
  });

  final bool isUndated;
  final MemoryType selectedType;
  final String dateText;
  final String? timeText;
  final bool reminderEnabled;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback? onClearTime;
  final ValueChanged<MemoryType> onTypeChanged;
  final Widget? specialFields;
  final bool showRecurrenceHint;
  final VoidCallback onRecurrenceHintTap;
  final Widget recordEditor;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = keyboardVisible || constraints.maxHeight < 520;
        final bottomPadding = keyboardVisible ? 8.0 : 24.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
              child: Column(
                children: [
                  if (!isUndated)
                    EditorMetadataBar(
                      selectedType: selectedType,
                      dateText: dateText,
                      timeText: timeText,
                      reminderEnabled: reminderEnabled,
                      onDateTap: onDateTap,
                      onTimeTap: onTimeTap,
                      onClearTime: onClearTime,
                      onTypeChanged: onTypeChanged,
                    ),
                  if (specialFields != null) ...[
                    SizedBox(height: compact ? 6 : 8),
                    specialFields!,
                  ],
                  if (showRecurrenceHint) ...[
                    SizedBox(height: compact ? 6 : 8),
                    RecurrenceHint(onTap: onRecurrenceHintTap),
                  ],
                  if (!isUndated || specialFields != null || showRecurrenceHint)
                    SizedBox(height: compact ? 8 : 10),
                  Expanded(child: recordEditor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
