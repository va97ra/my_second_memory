import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/feed_layout_provider.dart';
import '../../../memory_items/memory_items.dart';
import 'feed_day_rail.dart';
import 'feed_groups_view.dart';

/// Содержимое страницы ленты: группы записей выбранного периода и шкала дней,
/// которая появляется, пока карточку несут.
class FeedBody extends StatefulWidget {
  const FeedBody({
    super.key,
    required this.allDates,
    required this.searching,
    required this.filter,
    required this.layout,
    required this.loadState,
  });

  /// Показаны ли записи всех дат, а не одной страницы.
  final bool allDates;

  /// Набран ли поисковый запрос.
  final bool searching;
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
            builder: (context, constraints) => FeedGroupsView(
              allDates: allDates,
              searching: widget.searching,
              filter: filter,
              layout: layout,
              columns: memoryStickerColumns(constraints.maxWidth),
              carry: _carry,
            ),
          ),
        ),
        Positioned.fill(child: FeedDayRail(carry: _carry)),
      ],
    );
  }
}
