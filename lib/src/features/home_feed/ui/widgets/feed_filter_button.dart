part of '../home_feed_screen.dart';

class _FeedFilterButton extends StatelessWidget {
  const _FeedFilterButton({
    required this.selected,
    required this.onSelected,
    required this.allowsRecurring,
  });

  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelected;

  /// Записки не повторяются, поэтому на их закладке таких фильтров нет.
  final bool allowsRecurring;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    // The same square as every other button on the page.
    return PopupMenuButton<FeedFilter>(
      key: const ValueKey('feed_filter'),
      tooltip: strings.feedFilter,
      initialValue: selected,
      onSelected: onSelected,
      icon: const Icon(Icons.tune_rounded),
      iconSize: 22,
      style: notebookIconButtonStyle(),
      itemBuilder: (context) {
        return [
          for (final filter in FeedFilter.values)
            if (allowsRecurring || filter.recurringFrequency == null)
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
      FeedFilter.recurringMonthly => strings.monthlyRecurring,
      FeedFilter.recurringYearly => strings.yearlyRecurring,
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
      FeedFilter.recurringMonthly => Icons.sync_rounded,
      FeedFilter.recurringYearly => Icons.event_repeat_rounded,
    };
  }
}
