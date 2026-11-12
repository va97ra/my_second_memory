import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/feed_layout_provider.dart';
import '../../../memory_items/memory_items.dart';
import '../feed_labels.dart';
import 'feed_day_drop_target.dart';
import 'feed_group_divider.dart';

/// Прокрутка ленты. Открывается на сегодняшнем дне: будущее лежит выше него,
/// и туда листают вверх, прошлое ниже.
class FeedGroupsView extends StatelessWidget {
  const FeedGroupsView({
    super.key,
    required this.allDates,
    required this.searching,
    required this.filter,
    required this.layout,
    required this.columns,
    required this.carry,
  });

  /// Отсюда прокрутка отсчитывается в обе стороны.
  static const _todayKey = ValueKey('feed_today');

  final bool allDates;

  /// Найденное смотрят сверху: иначе результат из будущего остался бы за экраном.
  final bool searching;
  final FeedFilter filter;
  final FeedLayout layout;
  final int columns;
  final StickerCarry carry;

  bool get _labelled => allDates || filter.recurringFrequency != null;

  StickerStamp get _stamp => filter.recurringFrequency == null
      ? StickerStamp.time
      : StickerStamp.dayAndTime;

  Widget _label(BuildContext context, DateTime period) {
    final label = FeedGroupDivider(
      label: feedGroupLabel(context, filter, period, allDates: allDates),
    );
    // На подпись дня можно бросить листок. Только среди всех дат: там период —
    // это день. Группы по месяцу в фильтре «Каждый год» дня не называют.
    return allDates ? FeedDayDropTarget(day: period, child: label) : label;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final split =
        searching ? 0 : layout.todayGroupIndex(today, allDates: allDates);
    final future = layout.groups.sublist(0, split);
    final rest = layout.groups.sublist(split);
    // Сегодняшний день виден, даже если записей на него нет: от него и листают.
    final marksToday = !searching &&
        allDates &&
        layout.itemIds.isNotEmpty &&
        (rest.isEmpty || rest.first.period != today);

    return CustomScrollView(
      key: const ValueKey('feed_dated_scroll'),
      center: _todayKey,
      // Найденное листают, чтобы рассмотреть: клавиатура тогда только
      // закрывает список.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // Одним куском: что лежит выше точки отсчёта, раскладывается снизу
        // вверх, и в обычной сетке первая карточка дня оказалась бы последней.
        if (future.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in future) ...[
                  if (_labelled) _label(context, group.period),
                  MemoryStickerWrap(
                    itemIds: group.itemIds,
                    columns: columns,
                    carry: carry,
                    stamp: _stamp,
                  ),
                ],
              ],
            ),
          ),
        const SliverToBoxAdapter(key: _todayKey, child: SizedBox.shrink()),
        // Пустой день молчит, а пустой список всех дат — нет: иначе не понять,
        // ничего не нашлось или список ещё не появился.
        if (allDates && layout.itemIds.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(AppStrings.of(context).feedNothingFound)),
          ),
        if (marksToday) SliverToBoxAdapter(child: _label(context, today)),
        for (final group in rest) ...[
          // Раскрытый период содержит много дней, поэтому они разделяются
          // подписями. В обычной ленте дня разделять нечего.
          if (_labelled)
            SliverToBoxAdapter(child: _label(context, group.period)),
          MemoryStickerGrid(
            itemIds: group.itemIds,
            columns: columns,
            carry: carry,
            stamp: _stamp,
          ),
        ],
        if (layout.doneItemIds.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: FeedGroupDivider(
              label: AppStrings.of(context).completedRecords,
            ),
          ),
          MemoryStickerGrid(
            itemIds: layout.doneItemIds,
            columns: columns,
            carry: carry,
            stamp: _labelled ? StickerStamp.dayAndTime : StickerStamp.time,
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}
