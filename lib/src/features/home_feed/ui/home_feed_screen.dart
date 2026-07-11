import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../domain/feed_rules.dart';
import '../state/feed_providers.dart';
import 'widgets/memory_item_card.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final loadState = ref.watch(memoryItemsLoadProvider);
    final filter = ref.watch(feedFilterProvider);
    final groups = ref.watch(feedGroupsProvider);
    final isEmpty = groups.isEmpty;

    if (loadState.isLoading || loadState.hasError) {
      return WarmGradientBackground(
        child: CustomScrollView(
          slivers: [
            MainSliverAppBar(title: strings.dayFeed),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: loadState.isLoading
                    ? const CircularProgressIndicator()
                    : Text(strings.loadFailed),
              ),
            ),
          ],
        ),
      );
    }

    return WarmGradientBackground(
      child: CustomScrollView(
        slivers: [
          MainSliverAppBar(title: strings.dayFeed),
          SliverToBoxAdapter(
            child: _FeedFilterButton(
              selected: filter,
              onSelected: (filter) {
                ref.read(feedFilterProvider.notifier).state = filter;
              },
            ),
          ),
          const SliverToBoxAdapter(child: _MemoryBanner()),
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.dynamic_feed_outlined,
                  title: strings.emptyFeed,
                  actionLabel: strings.addRecord,
                  onAction: () => context.go('/calendar'),
                ),
              ),
            )
          else
            for (final group in groups) ...[
              _FeedSectionHeader(date: group.date),
              _MemorySliverList(items: group.items, ref: ref),
            ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}

class _FeedFilterButton extends StatelessWidget {
  const _FeedFilterButton({
    required this.selected,
    required this.onSelected,
  });

  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final label = _labelFor(context, selected);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PopupMenuButton<FeedFilter>(
          tooltip: strings.feedFilter,
          initialValue: selected,
          onSelected: onSelected,
          itemBuilder: (context) {
            return [
              for (final filter in FeedFilter.values)
                PopupMenuItem(
                  value: filter,
                  child: Row(
                    children: [
                      Icon(
                        _iconFor(filter),
                        size: 19,
                        color: filter == selected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 10),
                      Text(_labelFor(context, filter)),
                    ],
                  ),
                ),
            ];
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD6E2EF)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF172033),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(BuildContext context, FeedFilter filter) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return switch (filter) {
      FeedFilter.all => strings.allRecords,
      FeedFilter.active => strings.activeRecords,
      FeedFilter.done => strings.completedRecords,
      FeedFilter.task => MemoryType.task.label(locale),
      FeedFilter.note => MemoryType.note.label(locale),
      FeedFilter.event => MemoryType.event.label(locale),
      FeedFilter.goal => MemoryType.goal.label(locale),
      FeedFilter.project => MemoryType.project.label(locale),
      FeedFilter.purchase => MemoryType.purchase.label(locale),
      FeedFilter.document => MemoryType.document.label(locale),
      FeedFilter.place => MemoryType.place.label(locale),
    };
  }

  IconData _iconFor(FeedFilter filter) {
    return switch (filter) {
      FeedFilter.all => Icons.dynamic_feed_outlined,
      FeedFilter.active => Icons.radio_button_unchecked,
      FeedFilter.done => Icons.check_circle_outline,
      FeedFilter.task => Icons.check_circle_outline,
      FeedFilter.note => Icons.notes,
      FeedFilter.event => Icons.event,
      FeedFilter.goal => Icons.flag_outlined,
      FeedFilter.project => Icons.folder_outlined,
      FeedFilter.purchase => Icons.shopping_bag_outlined,
      FeedFilter.document => Icons.description_outlined,
      FeedFilter.place => Icons.place_outlined,
    };
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
  const _FeedSectionHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final title = DateFormat.yMMMMd(locale).format(date);

    if (title.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 6),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(width: 4, height: 22),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF172033),
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
          showDate: false,
          onOpen: () {
            context.push('/memory/view/${Uri.encodeComponent(item.id)}');
          },
          onToggleDone: () {
            ref
                .read(memoryItemsControllerProvider.notifier)
                .toggleDone(item.id);
          },
          onArchive: () {
            ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
          },
        );
      },
    );
  }
}
