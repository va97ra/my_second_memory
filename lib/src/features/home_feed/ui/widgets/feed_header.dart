import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_filter_button.dart';
import '../../../../shared/ui/page_hint_button.dart';
import 'feed_period_row.dart';
import 'feed_search_row.dart';

/// Шапка страницы ленты: закладка, период и кнопки над ними.
class FeedHeader extends StatelessWidget {
  const FeedHeader({
    super.key,
    required this.title,
    required this.periodLabel,
    required this.filter,
    required this.onGoToToday,
    required this.onFilterSelected,
    required this.onPickDate,
    required this.onPrevious,
    required this.onNext,
    required this.searching,
    required this.searchHint,
    required this.onToggleSearch,
    required this.searchQuery,
    required this.onSearch,
  });

  /// Открыт ли поиск. Строка поиска встаёт на место периода.
  final bool searching;

  /// Где ищет поиск открытой закладки.
  final String searchHint;
  final VoidCallback onToggleSearch;
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final String title;
  final String? periodLabel;
  final FeedFilter filter;

  final VoidCallback? onGoToToday;
  final ValueChanged<FeedFilter> onFilterSelected;

  final VoidCallback? onPickDate;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return NotebookPageHeader(
      cardKey: const ValueKey('feed_header_card'),
      bands: [
        NotebookHeaderBand(
          child: Row(
            children: [
              SizedBox(
                  width: notebookHeaderSlot * 2,
                  child: Row(children: [
                    PageHintButton(hint: strings.feedPageHint),
                    IconButton(
                        key: const ValueKey('feed_search'),
                        tooltip: searching ? strings.closeSearch : searchHint,
                        isSelected: searching,
                        onPressed: onToggleSearch,
                        icon: const Icon(Icons.search_rounded, size: 22),
                        selectedIcon:
                            const Icon(Icons.search_off_rounded, size: 22),
                        style: notebookIconButtonStyle()),
                  ])),
              Expanded(
                // Длинное название закладки ужимается целиком, а не теряет
                // хвост в многоточии; короткое остаётся полного размера.
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
              MemoryFilterButton(
                selected: filter,
                onSelected: onFilterSelected,
                // Записки не повторяются: на их закладке фильтров повтора
                // нет.
                filters: [
                  for (final filter in FeedFilter.values)
                    if (periodLabel != null ||
                        filter.recurringFrequency == null)
                      filter,
                ],
              ),
            ],
          ),
        ),
        if (searching)
          NotebookHeaderBand(
            child: FeedSearchRow(
              query: searchQuery,
              hint: searchHint,
              onChanged: onSearch,
            ),
          )
        else if (periodLabel != null)
          NotebookHeaderBand(
            child: FeedPeriodRow(
              label: periodLabel!,
              onPickDate: onPickDate,
              onPrevious: onPrevious,
              onNext: onNext,
            ),
          ),
      ],
    );
  }
}
