import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../domain/feed_rules.dart';
import 'widgets/memory_item_card.dart';

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final items = ref.watch(memoryItemsControllerProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayFeed = smartFeedForDay(items, today);
    final yesterdayFeed = _itemsForExactDay(
      items,
      today.subtract(const Duration(days: 1)),
      todayFeed,
    );
    final dayBeforeYesterdayFeed = _itemsForExactDay(
      items,
      today.subtract(const Duration(days: 2)),
      todayFeed,
    );
    final isEmpty = todayFeed.isEmpty &&
        yesterdayFeed.isEmpty &&
        dayBeforeYesterdayFeed.isEmpty;

    return AppShell(
      currentIndex: 0,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(strings.dayFeed),
          ),
          const SliverToBoxAdapter(child: _MemoryBanner()),
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(strings.emptyFeed)),
            )
          else ...[
            _MemorySliverList(items: todayFeed, ref: ref),
            _FeedSectionHeader(title: strings.yesterdaySection),
            if (yesterdayFeed.isEmpty)
              _EmptyFeedSection(text: strings.noRecords)
            else
              _MemorySliverList(items: yesterdayFeed, ref: ref),
            _FeedSectionHeader(title: strings.dayBeforeYesterdaySection),
            if (dayBeforeYesterdayFeed.isEmpty)
              _EmptyFeedSection(text: strings.noRecords)
            else
              _MemorySliverList(items: dayBeforeYesterdayFeed, ref: ref),
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ],
      ),
    );
  }

  List<MemoryItem> _itemsForExactDay(
    List<MemoryItem> items,
    DateTime date,
    List<MemoryItem> alreadyShown,
  ) {
    final shownIds = alreadyShown.map((item) => item.id).toSet();
    final day = DateTime(date.year, date.month, date.day);
    return items.where((item) {
      return !item.isArchived &&
          !shownIds.contains(item.id) &&
          isSameDay(item.memoryDate, day);
    }).toList()
      ..sort((a, b) {
        final priority = b.priority.compareTo(a.priority);
        if (priority != 0) {
          return priority;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
  }
}

class _MemoryBanner extends StatelessWidget {
  const _MemoryBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 2.45,
              child: Image.asset(
                'assets/images/memory_banner.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0F172A).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedSectionHeader extends StatelessWidget {
  const _FeedSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _EmptyFeedSection extends StatelessWidget {
  const _EmptyFeedSection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _MemorySliverList extends StatelessWidget {
  const _MemorySliverList({
    required this.items,
    required this.ref,
  });

  final List<MemoryItem> items;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MemoryItemCard(
          item: item,
          onDelete: () {
            ref.read(memoryItemsControllerProvider.notifier).delete(item.id);
          },
        );
      },
    );
  }
}
