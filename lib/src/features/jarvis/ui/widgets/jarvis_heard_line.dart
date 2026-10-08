import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../state/jarvis_talk_controller.dart';

/// Что Джарвис слышит прямо сейчас — или почему не смог послушать.
///
/// Строка, а не плашка: живой текст подтверждает, что микрофон работает, а
/// причина отказа — ответ на нажатие, и стоит там же, где ждали ответа.
class JarvisHeardLine extends StatelessWidget {
  const JarvisHeardLine({required this.talk, super.key});

  final JarvisTalk talk;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final problem = talk.problem;
    final text = problem ??
        (talk.heard.isEmpty ? strings.jarvisListening : '«${talk.heard}»');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            problem == null ? Icons.graphic_eq_rounded : Icons.mic_off_rounded,
            color: problem == null
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              key: const ValueKey('jarvis_heard'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: problem == null ? null : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
