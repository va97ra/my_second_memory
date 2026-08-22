part of '../home_feed_screen.dart';

class _FeedGroupDivider extends StatelessWidget {
  const _FeedGroupDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Center(
        child: AppLabeledDivider(
          label: label,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

/// The notebook sheet starts this far below the top of the ruled background.
const double _sheetTopInset = 3;

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.title,
    required this.periodLabel,
    required this.filter,
    required this.showHelp,
    required this.alignToRuling,
    required this.onGoToToday,
    required this.onFilterSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onShowHelp,
  });

  final String title;
  final String? periodLabel;
  final FeedFilter filter;
  final bool showHelp;
  final bool alignToRuling;

  /// Null once the page on screen is already the current one.
  final VoidCallback? onGoToToday;
  final ValueChanged<FeedFilter> onFilterSelected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onShowHelp;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return NotebookPageHeader(
      cardKey: const ValueKey('feed_header_card'),
      alignToRuling: alignToRuling,
      sheetTopInset: _sheetTopInset,
      bands: [
        NotebookHeaderBand(
          child: Row(
            children: [
              if (showHelp)
                IconButton(
                  key: const ValueKey('feed_help'),
                  tooltip: strings.allFeatures,
                  onPressed: onShowHelp,
                  icon: const Icon(Icons.menu_book_rounded, size: 22),
                  style: notebookIconButtonStyle(),
                )
              else
                const SizedBox(width: notebookHeaderSlot),
              // Balances the today button on the right.
              const SizedBox(width: notebookHeaderSlot),
              Expanded(
                // Long section names shrink to fit rather than losing their
                // tail to an ellipsis; short ones keep the full size.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('feed_today'),
                tooltip: strings.backToToday,
                onPressed: onGoToToday,
                icon: const Icon(Icons.today_rounded, size: 22),
                style: notebookIconButtonStyle(),
              ),
              _FeedFilterButton(
                selected: filter,
                onSelected: onFilterSelected,
              ),
            ],
          ),
        ),
        if (periodLabel != null)
          NotebookHeaderBand(
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('feed_previous_period'),
                  tooltip: strings.previousPeriod,
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  style: notebookIconButtonStyle(),
                ),
                Expanded(
                  child: Text(
                    periodLabel!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('feed_next_period'),
                  tooltip: strings.nextPeriod,
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  style: notebookIconButtonStyle(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MemorySliverList extends StatelessWidget {
  const _MemorySliverList({
    required this.itemIds,
    required this.showDate,
  });

  final List<String> itemIds;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    if (itemIds.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.builder(
      itemCount: itemIds.length,
      itemBuilder: (context, index) {
        return _FeedMemoryCard(
          itemId: itemIds[index],
          showDate: showDate,
        );
      },
    );
  }
}

class _FeedMemoryCard extends ConsumerWidget {
  const _FeedMemoryCard({
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
