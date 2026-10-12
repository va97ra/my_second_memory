import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Начало разговора: приветствие дворецкого.
///
/// Кнопок-примеров здесь больше нет: Джарвису говорят голосом, а три кнопки
/// только занимали место (решение владельца 11 октября 2026).
class JarvisEmptyView extends StatelessWidget {
  const JarvisEmptyView({super.key});

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
        ],
      ),
    );
  }
}
