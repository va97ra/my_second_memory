import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/feed_layout_provider.dart';
import '../../state/feed_providers.dart';
import '../feed_labels.dart';
import 'feed_group_divider.dart';
import 'memory_sliver_list.dart';

/// Содержимое страницы ленты: группы записей выбранного периода.
class FeedBody extends StatelessWidget {
  const FeedBody({
    super.key,
    required this.section,
    required this.hasQuery,
    required this.filter,
    required this.layout,
    required this.loadState,
  });

  final FeedSection section;
  /// Есть ли в строке поиска запрос.
  final bool hasQuery;
  final FeedFilter filter;
  final FeedLayout layout;
  final AsyncValue<void> loadState;

  @override
  Widget build(BuildContext context) {
    if (loadState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (loadState.hasError) {
      return Center(child: Text(AppStrings.of(context).loadFailed));
    }
    // Запрос на дне раскрывает ленту на все даты, и дни разделяются
    // подписями.
    final allDates = hasQuery && section == FeedSection.day;

    return KeyedSubtree(
      key: ValueKey(
        'feed_content_${section.name}_${filter.name}_${allDates}_'
        '${layout.query.anchorDate.toIso8601String()}',
      ),
      child: CustomScrollView(
        key: const ValueKey('feed_dated_scroll'),
        // Найденное листают, чтобы рассмотреть: клавиатура тогда только
        // закрывает список.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Пустая лента молчит, а пустой поиск — нет: иначе не понять,
          // ничего не нашлось или список ещё не появился.
          if (hasQuery && layout.groups.isEmpty)
            SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: Text(AppStrings.of(context).feedNothingFound))),
          for (final group in layout.groups) ...[
            // Раскрытый период содержит много дней, поэтому они разделяются
            // подписями. В обычной ленте дня разделять нечего.
            if (allDates || filter.recurringFrequency != null)
              SliverToBoxAdapter(
                child: FeedGroupDivider(
                  label: feedGroupLabel(context, filter, group.period,
                      allDates: allDates),
                ),
              ),
            MemorySliverList(
              itemIds: group.itemIds,
              showDate: filter.recurringFrequency == RecurrenceFrequency.yearly,
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}
