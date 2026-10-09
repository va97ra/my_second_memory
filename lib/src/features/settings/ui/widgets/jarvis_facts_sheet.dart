import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jarvis/jarvis.dart';

Future<void> showJarvisFactsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const JarvisFactsSheet(),
  );
}

/// Что хозяин просил Джарвиса запомнить. Всё видно и всё можно стереть:
/// это память о человеке, и решает о ней он сам.
class JarvisFactsSheet extends ConsumerWidget {
  const JarvisFactsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final facts = ref.watch(jarvisFactsProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                strings.jarvisFacts,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (facts.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child:
                    Text(strings.jarvisFactsEmpty, textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final fact in facts.reversed)
                      ListTile(
                        key: ValueKey('jarvis_fact_$fact'),
                        title: Text(fact),
                        trailing: IconButton(
                          tooltip: strings.jarvisFactForget,
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => ref
                              .read(jarvisFactsProvider.notifier)
                              .forget(fact),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
