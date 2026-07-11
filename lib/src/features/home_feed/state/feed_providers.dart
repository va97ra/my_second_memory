import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/state/memory_items_controller.dart';
import '../domain/feed_rules.dart';

final feedFilterProvider = StateProvider<FeedFilter>((ref) => FeedFilter.all);

final feedLayoutProvider = Provider<FeedLayout>((ref) {
  final groups = groupItemsByDate(
    ref.watch(memoryItemsControllerProvider),
    filter: ref.watch(feedFilterProvider),
  );
  return FeedLayout([
    for (final group in groups)
      FeedDayLayout(
        date: group.date,
        itemIds: [for (final item in group.items) item.id],
      ),
  ]);
});

class FeedLayout {
  const FeedLayout(this.days);

  final List<FeedDayLayout> days;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeedLayout || other.days.length != days.length) return false;
    for (var index = 0; index < days.length; index++) {
      if (days[index] != other.days[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(days);
}

class FeedDayLayout {
  const FeedDayLayout({required this.date, required this.itemIds});

  final DateTime date;
  final List<String> itemIds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeedDayLayout ||
        other.date != date ||
        other.itemIds.length != itemIds.length) {
      return false;
    }
    for (var index = 0; index < itemIds.length; index++) {
      if (itemIds[index] != other.itemIds[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(date, Object.hashAll(itemIds));
}
