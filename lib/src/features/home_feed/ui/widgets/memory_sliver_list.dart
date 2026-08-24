import 'package:flutter/material.dart';

import 'feed_memory_card.dart';

/// Список записей одной группы. Строится лениво: групп может быть много.
class MemorySliverList extends StatelessWidget {
  const MemorySliverList({
    super.key,
    required this.itemIds,
    required this.showDate,
  });

  final List<String> itemIds;

  /// Дата нужна только когда на странице лежит больше одного дня.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    if (itemIds.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.builder(
      itemCount: itemIds.length,
      itemBuilder: (context, index) => FeedMemoryCard(
        itemId: itemIds[index],
        showDate: showDate,
      ),
    );
  }
}
