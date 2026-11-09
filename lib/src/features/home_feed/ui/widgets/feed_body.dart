import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/feed_layout_provider.dart';
import '../../../memory_items/memory_items.dart';
import '../feed_labels.dart';
import 'feed_day_drop_target.dart';
import 'feed_day_rail.dart';
import 'feed_group_divider.dart';

/// Содержимое страницы ленты: группы записей выбранного периода и шкала дней,
/// которая появляется, пока карточку несут.
class FeedBody extends StatefulWidget {
  const FeedBody({
    super.key,
    required this.allDates,
    required this.filter,
    required this.layout,
    required this.loadState,
  });

  /// Показаны ли записи всех дат, а не одной страницы.
  final bool allDates;
  final FeedFilter filter;
  final FeedLayout layout;
  final AsyncValue<void> loadState;

  @override
  State<FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends State<FeedBody> {
  final _carry = StickerCarry();

  bool get allDates => widget.allDates;
  FeedFilter get filter => widget.filter;
  FeedLayout get layout => widget.layout;

  @override
  void dispose() {
    _carry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loadState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.loadState.hasError) {
      return Center(child: Text(AppStrings.of(context).loadFailed));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: ValueKey(
            'feed_content_${filter.name}_${allDates}_'
            '${layout.query.anchorDate.toIso8601String()}',
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => _scroll(
              context,
              memoryStickerColumns(constraints.maxWidth),
            ),
          ),
        ),
        Positioned.fill(child: FeedDayRail(carry: _carry)),
      ],
    );
  }

  Widget _scroll(BuildContext context, int columns) {
    return CustomScrollView(
        key: const ValueKey('feed_dated_scroll'),
        // Найденное листают, чтобы рассмотреть: клавиатура тогда только
        // закрывает список.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Пустой день молчит, а пустой список всех дат — нет: иначе не понять,
          // ничего не нашлось или список ещё не появился.
          if (allDates && layout.itemIds.isEmpty)
            SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: Text(AppStrings.of(context).feedNothingFound))),
          for (final group in layout.groups) ...[
            // Раскрытый период содержит много дней, поэтому они разделяются
            // подписями. В обычной ленте дня разделять нечего.
            if (allDates || filter.recurringFrequency != null)
              SliverToBoxAdapter(
                child: _dayLabel(
                  group.period,
                  FeedGroupDivider(
                    label: feedGroupLabel(context, filter, group.period,
                        allDates: allDates),
                  ),
                ),
              ),
            MemoryStickerGrid(
              itemIds: group.itemIds,
              columns: columns,
              carry: _carry,
              stamp: filter.recurringFrequency == null
                  ? StickerStamp.time
                  : StickerStamp.dayAndTime,
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
              carry: _carry,
              stamp: allDates || filter.recurringFrequency != null
                  ? StickerStamp.dayAndTime
                  : StickerStamp.time,
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
    );
  }

  /// На подпись дня можно бросить листок. Только среди всех дат: там период —
  /// это день. Группы по месяцу в фильтре «Каждый год» дня не называют.
  Widget _dayLabel(DateTime period, Widget label) =>
      allDates ? FeedDayDropTarget(day: period, child: label) : label;
}
