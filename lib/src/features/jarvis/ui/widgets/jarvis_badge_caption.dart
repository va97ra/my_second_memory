import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Подпись у значка Джарвиса: что он сейчас услышал или ответил, и
/// «Отменить», если ответ — сделанное действие. Весь разговор — в листе.
class JarvisBadgeCaption extends StatelessWidget {
  const JarvisBadgeCaption({required this.text, this.onUndo, super.key});

  final String text;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final strings = AppStrings.of(context);
    return Container(
      key: const ValueKey('jarvis_badge_caption'),
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          if (onUndo != null)
            NotebookPressable(
              key: const ValueKey('jarvis_badge_undo'),
              onTap: onUndo,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                child: Text(
                  strings.jarvisUndo,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: colors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
