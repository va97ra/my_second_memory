import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../../shared/ui/memory_card/memory_item_card.dart';
import '../../../memory_items/memory_items.dart';

/// Запись дня: получает идентификатор и читает запись сама.
class DayRecordCard extends ConsumerWidget {
  const DayRecordCard(this.itemId, {super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();
    return MemoryItemCard(
      item: item,
      showDate: false,
      compact: true,
      margin: const EdgeInsets.only(bottom: 4),
      onOpen: () => context.pageTurnPush(
        '/memory/item/${Uri.encodeComponent(item.id)}',
      ),
      onToggleDone: () => toggleMemoryDone(ref, item),
      onArchive: item.isArchived ? null : () => archiveMemory(ref, item),
      onRestore: item.isArchived ? () => restoreMemory(ref, item) : null,
    );
  }
}
