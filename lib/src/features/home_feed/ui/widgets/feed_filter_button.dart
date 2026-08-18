part of '../home_feed_screen.dart';

class _FeedFilterButton extends StatelessWidget {
  const _FeedFilterButton({
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 4),
  });

  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final label = _labelFor(context, selected);
    final maxButtonWidth =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(156.0, 240.0);

    return Padding(
      padding: padding,
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
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxButtonWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.expand_more_rounded, size: 18),
                  ],
                ),
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
      FeedFilter.all => Icons.view_agenda_rounded,
      FeedFilter.active => Icons.radio_button_unchecked_rounded,
      FeedFilter.done => Icons.task_alt_rounded,
      FeedFilter.task => Icons.task_alt_rounded,
      FeedFilter.note => Icons.sticky_note_2_rounded,
      FeedFilter.event => Icons.event_rounded,
      FeedFilter.goal => Icons.flag_rounded,
      FeedFilter.project => Icons.folder_rounded,
      FeedFilter.purchase => Icons.shopping_bag_rounded,
      FeedFilter.document => Icons.description_rounded,
      FeedFilter.place => Icons.location_on_rounded,
      FeedFilter.birthday => Icons.cake_rounded,
      FeedFilter.payment => Icons.payments_rounded,
    };
  }
}
