import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/state/memory_items_controller.dart';
import '../domain/feed_rules.dart';

final feedFilterProvider = StateProvider<FeedFilter>((ref) => FeedFilter.all);

final feedGroupsProvider = Provider<List<FeedDay>>((ref) {
  return groupItemsByDate(
    ref.watch(memoryItemsControllerProvider),
    filter: ref.watch(feedFilterProvider),
  );
});
