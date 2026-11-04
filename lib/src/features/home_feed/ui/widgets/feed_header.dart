import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/chrome/main_page_header.dart';
import '../../../../shared/ui/memory_filter_button.dart';
import 'feed_search_row.dart';

/// Шапка ленты и записок: стрелки периода по краям, посередине закладка и
/// период, нажатие на них открывает выбор дня.
class FeedHeader extends StatelessWidget {
  const FeedHeader({
    super.key,
    required this.hint,
    required this.title,
    required this.periodLabel,
    required this.filter,
    required this.filters,
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

  /// Открыт ли поиск. Строка поиска встаёт на место сведений и кнопок периода.
  final bool searching;

  /// Где ищет поиск этой страницы.
  final String searchHint;
  final VoidCallback onToggleSearch;
  final String searchQuery;
  final ValueChanged<String> onSearch;

  /// Подсказка страницы.
  final String hint;
  final String title;
  final String? periodLabel;
  final FeedFilter filter;

  /// Какие фильтры предлагает эта страница.
  final List<FeedFilter> filters;

  final VoidCallback? onGoToToday;
  final ValueChanged<FeedFilter> onFilterSelected;

  final VoidCallback? onPickDate;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hasPeriod = periodLabel != null && !searching;

    return MainPageHeader(
      cardKey: const ValueKey('feed_header_card'),
      hint: hint,
      leading: [
        if (hasPeriod)
          // Листать нечего — стрелки нет, а не нажимается впустую. Слот за ней
          // остаётся: кнопки не переезжают.
          if (onPrevious == null)
            const SizedBox.shrink()
          else
            IconButton(
              key: const ValueKey('feed_previous_period'),
              tooltip: strings.previousPeriod,
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded, size: 24),
              style: notebookIconButtonStyle(),
            ),
        IconButton(
          key: const ValueKey('feed_search'),
          tooltip: searching ? strings.closeSearch : searchHint,
          isSelected: searching,
          onPressed: onToggleSearch,
          icon: const Icon(Icons.search_rounded, size: 22),
          selectedIcon: const Icon(Icons.search_off_rounded, size: 22),
          style: notebookIconButtonStyle(),
        ),
      ],
      trailing: [
        if (hasPeriod)
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
          filters: filters,
        ),
        if (hasPeriod)
          if (onNext == null)
            const SizedBox.shrink()
          else
            IconButton(
              key: const ValueKey('feed_next_period'),
              tooltip: strings.nextPeriod,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded, size: 24),
              style: notebookIconButtonStyle(),
            ),
      ],
      center: searching
          ? FeedSearchRow(
              query: searchQuery,
              hint: searchHint,
              onChanged: onSearch,
            )
          : _center(),
    );
  }

  Widget _center() {
    final title = NotebookHeaderTitle(
      title: Text(this.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      details: periodLabel == null
          ? null
          : Text(periodLabel!, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
    if (periodLabel == null) return title;
    // Свой прозрачный материал: без него волна нажатия уходит материалу
    // `Scaffold` и рисуется поверх задника.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const ValueKey('feed_pick_date'),
        onTap: onPickDate,
        borderRadius: BorderRadius.circular(8),
        child: title,
      ),
    );
  }
}
