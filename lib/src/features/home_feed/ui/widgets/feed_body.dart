import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/feed_providers.dart';
import '../feed_labels.dart';
import 'feed_group_divider.dart';
import 'memory_sliver_list.dart';

/// Содержимое страницы ленты: группы записей выбранного периода.
class FeedBody extends StatelessWidget {
  const FeedBody({
    super.key,
    required this.section,
    required this.filter,
    required this.layout,
    required this.loadState,
  });

  final FeedSection section;
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

    return KeyedSubtree(
      key: ValueKey(
        'feed_content_${section.name}_${filter.name}_'
        '${layout.query.anchorDate.toIso8601String()}',
      ),
      child: CustomScrollView(
        key: const ValueKey('feed_dated_scroll'),
        slivers: [
          for (final group in layout.groups) ...[
            // Раскрытый период содержит много дней, поэтому они разделяются
            // подписями. В обычной ленте дня разделять нечего.
            if (filter.recurringFrequency != null)
              SliverToBoxAdapter(
                child: FeedGroupDivider(
                  label: feedGroupLabel(context, filter, group.period),
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
