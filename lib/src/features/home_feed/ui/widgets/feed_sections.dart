part of '../home_feed_screen.dart';

class _FeedDayDivider extends StatelessWidget {
  const _FeedDayDivider({
    required this.label,
    required this.expanded,
    required this.collapsible,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool expanded;
  final bool collapsible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final divider = AppLabeledDivider(
      label: label,
      trailingIcon: collapsible
          ? expanded
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
    if (!collapsible) return divider;
    return Semantics(
      button: true,
      expanded: expanded,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(height: 48, child: Center(child: divider)),
        ),
      ),
    );
  }
}

String _feedDividerLabel(BuildContext context, DateTime date) {
  final strings = AppStrings.of(context);
  final locale = Localizations.localeOf(context).languageCode;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final checked = DateTime(date.year, date.month, date.day);
  final shortDate = DateFormat(
    locale == 'ru' ? 'd MMMM' : 'MMMM d',
    locale,
  ).format(checked);
  if (checked == today) return '${strings.today} · $shortDate';
  if (checked == today.subtract(const Duration(days: 1))) {
    return '${strings.yesterday} · $shortDate';
  }
  return DateFormat(
    locale == 'ru' ? 'd MMMM y' : 'MMMM d, y',
    locale,
  ).format(checked);
}

String _feedDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.title,
    required this.filter,
    required this.onFilterSelected,
  });

  final String title;
  final FeedFilter filter;
  final ValueChanged<FeedFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            _FeedFilterButton(
              selected: filter,
              onSelected: onFilterSelected,
              padding: EdgeInsets.zero,
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
        return _FeedMemoryCard(
          itemId: itemIds[index],
        );
      },
    );
  }
}

class _UndatedNotesList extends StatelessWidget {
  const _UndatedNotesList({required this.itemIds});

  final List<String> itemIds;

  @override
  Widget build(BuildContext context) {
    if (itemIds.isEmpty) return const SizedBox.shrink();

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final estimatedCardHeight = textScale <= 1.3
        ? 76 + ((textScale - 1).clamp(0.0, 0.3) * 40)
        : 88 + (((textScale - 1.3) / 0.7).clamp(0.0, 1.0) * 64);
    final contentHeight = itemIds.length * (estimatedCardHeight + 8);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.32;

    return SizedBox(
      height: contentHeight.clamp(0.0, maxHeight),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: itemIds.length,
        itemBuilder: (context, index) => _UndatedNoteCard(
          itemId: itemIds[index],
        ),
      ),
    );
  }
}

class _UndatedNoteCard extends ConsumerWidget {
  const _UndatedNoteCard({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();
    return MemoryItemCard(
      item: item,
      showDate: false,
      compact: true,
      denseFeedLayout: true,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      onOpen: () =>
          context.push('/memory/view/${Uri.encodeComponent(item.id)}'),
      onArchive: () {
        ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
      },
    );
  }
}

class _FeedMemoryCard extends ConsumerWidget {
  const _FeedMemoryCard({
    required this.itemId,
  });

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();
    return MemoryItemCard(
      item: item,
      showDate: false,
      compact: true,
      denseFeedLayout: true,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
