import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../../shared/ui/memory_card/memory_item_card.dart';
import '../../../memory_items/memory_items.dart';

/// Записи выбранного дня.
///
/// Из дня запись открывается в редакторе, а не в безопасном просмотре: сюда
/// заходят, чтобы править.
class DayRecordsList extends ConsumerWidget {
  const DayRecordsList({super.key, required this.items});

  final List<MemoryItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
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
      },
    );
  }
}
