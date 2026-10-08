import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../state/jarvis_message.dart';
import 'jarvis_bubble_surface.dart';

/// Одна реплика. Под ответом Джарвиса — «Отменить», если это последнее
/// действие, и «Показать», если ответ касается страницы.
class JarvisMessageBubble extends StatelessWidget {
  const JarvisMessageBubble({
    required this.message,
    required this.undoable,
    required this.onUndo,
    required this.onShow,
    super.key,
  });

  final JarvisMessage message;
  final bool undoable;
  final VoidCallback onUndo;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fromPerson = !message.fromJarvis;
    final hasActions = undoable || message.link != null;
    final bubble = JarvisBubbleSurface(
      fromPerson: fromPerson,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, hasActions ? 2 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: fromPerson && !_isScreenTheme(context)
                        ? scheme.onPrimaryContainer
                        : null,
                  ),
            ),
            if (hasActions)
              Wrap(
                spacing: 4,
                children: [
                  if (undoable)
                    TextButton.icon(
                      key: ValueKey('jarvis_undo_${message.id}'),
                      onPressed: onUndo,
                      icon: const Icon(Icons.undo_rounded),
                      label: Text(strings.jarvisUndo),
                    ),
                  if (message.link != null)
                    TextButton.icon(
                      key: ValueKey('jarvis_show_${message.id}'),
                      onPressed: onShow,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(strings.jarvisShow),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
    // Реплика не тянется на всю ширину: свободный край показывает, с чьей
    // она стороны.
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: fromPerson ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * (fromPerson ? 0.82 : 0.9),
          ),
          child: bubble,
        ),
      ),
    );
  }

  static bool _isScreenTheme(BuildContext context) =>
      ScreenVisuals.maybeOf(context) != null;
}
