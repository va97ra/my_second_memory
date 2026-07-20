import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../memory_items/state/memory_item_selectors.dart';
import '../../recurrence/ui/recurring_informers.dart';
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
    final layout = ref.watch(feedLayoutProvider);
    final isEmpty = layout.days.isEmpty;
    final showHints = ref.watch(appHintsProvider);

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
          if (showHints) const SliverToBoxAdapter(child: _FeedUsageHint()),
          const SliverToBoxAdapter(child: RecurringInformers()),
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
            for (final group in layout.days) ...[
              _FeedSectionHeader(date: group.date),
              _MemorySliverList(itemIds: group.itemIds),
            ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}

class _FeedUsageHint extends StatelessWidget {
  const _FeedUsageHint();

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Material(
        color: colors.primaryContainer.withValues(alpha: 0.42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.32)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ru ? 'Как пользоваться' : 'How to use the app',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 5),
              _HintLine(
                icon: Icons.calendar_month_outlined,
                text: ru
                    ? 'Календарь → дата → «Добавить запись»'
                    : 'Calendar → date → Add record',
              ),
              _HintLine(
                icon: Icons.event_repeat,
                text: ru
                    ? '↻ включает повтор, галочка завершает запись'
                    : '↻ repeats; the check mark completes a record',
              ),
              _HintLine(
                icon: Icons.archive_outlined,
                text: ru
                    ? 'Архив переносит запись в Базу памяти'
                    : 'Archive moves a record to Memory library',
              ),
              const SizedBox(height: 3),
              Text(
                ru
                    ? 'Подсказки отключаются в Настройки → Показывать подсказки.'
                    : 'Turn hints off in Settings → Show hints.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
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
                            : Theme.of(context).colorScheme.onSurfaceVariant,
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
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
      FeedFilter.birthday => MemoryType.birthday.label(locale),
      FeedFilter.payment => MemoryType.payment.label(locale),
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
      FeedFilter.birthday => Icons.cake_outlined,
      FeedFilter.payment => Icons.payments_outlined,
    };
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
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(width: 4, height: 22),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
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
    required this.itemIds,
  });

  final List<String> itemIds;

  @override
  Widget build(BuildContext context) {
    if (itemIds.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.builder(
      itemCount: itemIds.length,
      itemBuilder: (context, index) {
        return _FeedMemoryCard(itemId: itemIds[index]);
      },
    );
  }
}

class _FeedMemoryCard extends ConsumerWidget {
  const _FeedMemoryCard({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();
    return MemoryItemCard(
      item: item,
      showDate: false,
      onOpen: () {
        context.push('/memory/view/${Uri.encodeComponent(item.id)}');
      },
      onToggleDone: () {
        ref.read(memoryItemsControllerProvider.notifier).toggleDone(item.id);
      },
      onArchive: () {
        ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
      },
    );
  }
}
