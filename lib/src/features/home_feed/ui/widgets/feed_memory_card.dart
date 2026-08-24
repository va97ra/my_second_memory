import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../memory_items/memory_items.dart';
import '../../../../shared/ui/memory_card/memory_item_card.dart';

/// Карточка ленты, подписанная на одну запись.
///
/// Подписка идёт по идентификатору: правка одной записи перерисовывает её
/// карточку, а не весь список.
class FeedMemoryCard extends ConsumerWidget {
  const FeedMemoryCard({
    super.key,
    required this.itemId,
    required this.showDate,
  });

  final String itemId;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();

    return MemoryItemCard(
      item: item,
      showDate: showDate,
      compact: true,
      denseFeedLayout: true,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      onOpen: () => context.pageTurnPush(
        '/memory/view/${Uri.encodeComponent(item.id)}',
      ),
      onToggleDone: () {
        ref.read(memoryItemsControllerProvider.notifier).toggleDone(item.id);
      },
      onArchive: () {
        ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
      },
    );
  }
}
