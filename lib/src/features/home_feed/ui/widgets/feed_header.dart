import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_filter_button.dart';

/// Шапка страницы ленты: закладка, период и кнопки над ними.
class FeedHeader extends StatelessWidget {
  const FeedHeader({
    super.key,
    required this.title,
    required this.periodLabel,
    required this.filter,
    required this.showHelp,
    required this.onGoToToday,
    required this.onFilterSelected,
    required this.onPickDate,
    required this.onPrevious,
    required this.onNext,
    required this.onShowHelp,
  });

  final String title;
  final String? periodLabel;
  final FeedFilter filter;
  final bool showHelp;

  /// Null, когда на экране уже сегодняшняя страница.
  final VoidCallback? onGoToToday;
  final ValueChanged<FeedFilter> onFilterSelected;

  /// Null на закладке записок: у них нет дня, который можно выбрать.
  final VoidCallback? onPickDate;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onShowHelp;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return NotebookPageHeader(
      cardKey: const ValueKey('feed_header_card'),
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
              // Уравновешивает кнопку «сегодня» справа.
              const SizedBox(width: notebookHeaderSlot),
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
                    if (periodLabel != null || filter.recurringFrequency == null)
                      filter,
                ],
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
                  child: InkWell(
                    key: const ValueKey('feed_pick_date'),
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
