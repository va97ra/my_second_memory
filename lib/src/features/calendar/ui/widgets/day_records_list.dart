import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../../shared/ui/memory_card/memory_item_card.dart';
import '../../../memory_items/memory_items.dart';

/// Записи выбранного дня.
///
/// Из дня запись открывается в редакторе, а не в безопасном просмотре: сюда
/// заходят, чтобы править.
class DayRecordsList extends StatelessWidget {
  const DayRecordsList({super.key, required this.itemIds});

  final List<String> itemIds;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      itemCount: itemIds.length,
      itemBuilder: (context, index) => _DayRecordCard(itemIds[index]),
    );
  }
}

/// Запись дня: получает идентификатор и читает запись сама.
class _DayRecordCard extends ConsumerWidget {
  const _DayRecordCard(this.itemId);

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
