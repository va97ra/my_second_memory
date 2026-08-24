import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recurrence/state/recurrence_controller.dart';
import 'memory_items_controller.dart';

/// Действия над записью из списка.
///
/// Вхождение повтора не лежит в хранилище отдельной строкой: его правка идёт в
/// серию как переопределение. Поэтому каждое действие сначала спрашивает, что
/// перед ним, и только потом выбирает, кому его передать.
void toggleMemoryDone(WidgetRef ref, MemoryItem item) {
  if (item.isGeneratedOccurrence) {
    ref
        .read(recurrenceSeriesControllerProvider.notifier)
        .toggleOccurrenceDone(item);
    return;
  }
  ref.read(memoryItemsControllerProvider.notifier).toggleDone(item.id);
}

void archiveMemory(WidgetRef ref, MemoryItem item) {
  if (item.isGeneratedOccurrence) {
    ref
        .read(recurrenceSeriesControllerProvider.notifier)
        .archiveOccurrence(item);
    return;
  }
  ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
}

void restoreMemory(WidgetRef ref, MemoryItem item) {
  if (item.isGeneratedOccurrence) {
    ref
        .read(recurrenceSeriesControllerProvider.notifier)
        .restoreOccurrence(item);
    return;
  }
  ref.read(memoryItemsControllerProvider.notifier).restore(item.id);
}
