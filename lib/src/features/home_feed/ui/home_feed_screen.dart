import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../domain/feed_rules.dart';
import 'widgets/memory_item_card.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final items = ref.watch(memoryItemsControllerProvider);
    final feed = smartFeedForDay(items, DateTime.now());

    return AppShell(
      currentIndex: 0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add'),
        icon: const Icon(Icons.add),
        label: Text(strings.add),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(strings.today),
          ),
          if (feed.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(strings.emptyFeed)),
            )
          else
            SliverList.builder(
              itemCount: feed.length,
              itemBuilder: (context, index) {
                final item = feed[index];
                return MemoryItemCard(
                  item: item,
                  onArchive: () {
                    ref
                        .read(memoryItemsControllerProvider.notifier)
                        .archive(item.id);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
