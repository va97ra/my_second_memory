import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/gigachat_limit.dart';
import '../../state/jarvis_brain_providers.dart';

/// Сколько осталось от пакета GigaChat: тонкая полоска и строка под
/// заголовком листа. Без ключа её нет — нейросеть не подключена, и мерить
/// нечего. Остаток спрашивается, когда лист открывают.
class JarvisLimitBar extends ConsumerStatefulWidget {
  const JarvisLimitBar({super.key});

  @override
  ConsumerState<JarvisLimitBar> createState() => _JarvisLimitBarState();
}

class _JarvisLimitBarState extends ConsumerState<JarvisLimitBar> {
  @override
  void initState() {
    super.initState();
    if (ref.read(gigaChatClientProvider) != null) {
      unawaited(ref.read(gigaChatLimitProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(gigaChatClientProvider) == null) {
      return const SizedBox.shrink();
    }
    final limit = ref.watch(gigaChatLimitProvider);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final left = limit.left;
    final share = limit.share;
    final label = left != null
        ? strings.gigaChatLeft(left)
        : limit.spentThisMonth > 0
            ? strings.gigaChatSpent(limit.spentThisMonth)
            : null;
    if (label == null) return const SizedBox.shrink();
    // Меньше десятой части — полоска предупреждает цветом, без плашек.
    final low = share != null && share < 0.1;
    return Padding(
      key: const ValueKey('jarvis_limit'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (share != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 4,
                color: low
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
