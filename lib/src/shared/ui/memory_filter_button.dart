import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'memory_card/memory_item_presentation.dart';

/// Фильтр записей. Такой же квадрат, как остальные кнопки страницы.
///
/// Кнопка только показывает и сообщает выбор: какие фильтры уместны на этой
/// странице, решает та страница. В ленте это зависит от закладки, в архиве —
/// от того, что там вообще может лежать.
class MemoryFilterButton extends StatelessWidget {
  const MemoryFilterButton({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<FeedFilter> filters;
  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<FeedFilter>(
      key: const ValueKey('feed_filter'),
      tooltip: AppStrings.of(context).feedFilter,
      initialValue: selected,
      onSelected: onSelected,
      icon: const Icon(Icons.tune_rounded),
      iconSize: 22,
      style: notebookIconButtonStyle(),
      itemBuilder: (context) => [
        for (final filter in filters)
          PopupMenuItem(
            value: filter,
            child: Row(
              children: [
                Icon(
                  _iconFor(filter),
                  size: 19,
                  color: filter == selected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(_labelFor(context, filter)),
              ],
            ),
          ),
      ],
    );
  }

  String _labelFor(BuildContext context, FeedFilter filter) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final type = filter.memoryType;
    if (type != null) return type.label(locale);

    return switch (filter) {
      FeedFilter.all => strings.allRecords,
      FeedFilter.active => strings.activeRecords,
      FeedFilter.done => strings.completedRecords,
      FeedFilter.recurringMonthly => strings.monthlyRecurring,
      FeedFilter.recurringYearly => strings.yearlyRecurring,
      _ => '',
    };
  }

  /// Значок вида записи берётся там же, где его берут карточки: второй список
  /// значков разошёлся бы с первым.
  IconData _iconFor(FeedFilter filter) {
    final type = filter.memoryType;
    if (type != null) return memoryTypeIcon(type);

    return switch (filter) {
      FeedFilter.all => Icons.view_agenda_rounded,
      FeedFilter.active => Icons.radio_button_unchecked_rounded,
      FeedFilter.done => Icons.task_alt_rounded,
      FeedFilter.recurringMonthly => Icons.sync_rounded,
      FeedFilter.recurringYearly => Icons.event_repeat_rounded,
      _ => Icons.view_agenda_rounded,
    };
  }
}
