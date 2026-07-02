import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6FAFF),
              Color(0xFFF3F6FA),
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              backgroundColor: const Color(0xFFF6FAFF),
              surfaceTintColor: Colors.transparent,
              title: Text(
                strings.dayFeed,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF172033),
                    ),
              ),
            ),
            const SliverToBoxAdapter(child: _MemoryBanner()),
            if (isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child:
                    Center(child: _EmptyFeedMessage(text: strings.emptyFeed)),
              )
            else ...[
              _MemorySliverList(items: todayFeed, ref: ref),
              if (yesterdayFeed.isNotEmpty) ...[
                _FeedSectionHeader(title: strings.yesterdaySection),
                _MemorySliverList(items: yesterdayFeed, ref: ref),
              ],
              if (dayBeforeYesterdayFeed.isNotEmpty) ...[
                _FeedSectionHeader(title: strings.dayBeforeYesterdaySection),
                _MemorySliverList(items: dayBeforeYesterdayFeed, ref: ref),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ],
        ),
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.24),
                      const Color(0xFFDBEAFE).withValues(alpha: 0.32),
                      Colors.white.withValues(alpha: 0.1),
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
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 7),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE7F3)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF172033),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFeedMessage extends StatelessWidget {
  const _EmptyFeedMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE7F3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  Icons.dynamic_feed_outlined,
                  color: Color(0xFF2563EB),
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
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
          onOpen: () {
            context.push('/memory/item/${Uri.encodeComponent(item.id)}');
          },
          onToggleDone: () {
            ref
                .read(memoryItemsControllerProvider.notifier)
                .toggleDone(item.id);
          },
        );
      },
    );
  }
}
