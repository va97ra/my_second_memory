import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../memory_items/memory_items.dart';

/// Подпись дня, на которую можно бросить карточку: запись переедет на этот день.
class FeedDayDropTarget extends ConsumerWidget {
  const FeedDayDropTarget({super.key, required this.day, required this.child});

  final DateTime day;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final item = ref.read(memoryItemByIdProvider(details.data));
        if (item != null) moveMemoryToDay(ref, item, day);
      },
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: candidates.isEmpty
            ? Colors.transparent
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
        child: child,
      ),
    );
  }
}
