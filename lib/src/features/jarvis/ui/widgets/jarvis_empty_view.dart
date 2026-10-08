import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Начало разговора: приветствие дворецкого и три примера, с чего начать.
///
/// Примеры — кнопки: нажатый пример уходит Джарвису как сказанный. Так
/// новичок сразу видит, что Джарвис умеет, и не учит это по подсказке.
class JarvisEmptyView extends StatelessWidget {
  const JarvisEmptyView({required this.onExample, super.key});

  final ValueChanged<String> onExample;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.support_agent_rounded, size: 40, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            strings.jarvisGreeting,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in strings.jarvisExamples)
                OutlinedButton(
                  key: ValueKey('jarvis_example_$example'),
                  onPressed: () => onExample(example),
                  child: Text('«$example»'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
