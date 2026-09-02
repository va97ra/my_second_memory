import 'package:flutter/material.dart';
import 'recurrence_hint.dart';

/// Содержимое редактора: поле записи, метаданные и особые поля вида.
class EditorBody extends StatelessWidget {
  const EditorBody({
    super.key,
    required this.isUndated,
    required this.specialFields,
    required this.showRecurrenceHint,
    required this.onRecurrenceHintTap,
    required this.recordEditor,
  });

  final bool isUndated;
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
                  if (specialFields != null) ...[
                    SizedBox(height: compact ? 6 : 8),
                    specialFields!,
                  ],
                  if (showRecurrenceHint) ...[
                    SizedBox(height: compact ? 6 : 8),
                    RecurrenceHint(onTap: onRecurrenceHintTap),
                  ],
                  if (specialFields != null || showRecurrenceHint)
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
