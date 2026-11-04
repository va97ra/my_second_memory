import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/feed_layout_provider.dart';
import '../../state/feed_providers.dart';
import '../feed_labels.dart';
import 'feed_body.dart';
import 'feed_header.dart';

/// Страница ленты: шапка и содержимое на одном листе.
class FeedPage extends ConsumerWidget {
  const FeedPage({
    super.key,
    required this.view,
    required this.layout,
    required this.loadState,
    required this.onGoToToday,
    required this.onFilterSelected,
    required this.onMovePeriod,
    required this.onPickDate,
  });

  final FeedViewState view;
  final FeedLayout layout;
  final AsyncValue<void> loadState;
  final VoidCallback? onGoToToday;
  final ValueChanged<FeedFilter> onFilterSelected;
  final ValueChanged<int> onMovePeriod;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dated = !view.allDates;
    final feed = ref.read(feedViewProvider.notifier);
    final strings = AppStrings.of(context);
    final content = Column(
      children: [
        FeedHeader(
          searching: view.searching,
          hint: strings.feedPageHint,
          searchHint: strings.searchAllDates,
          onToggleSearch: feed.toggleSearch,
          searchQuery: view.searchQuery,
          onSearch: feed.search,
          title: view.filterSpansAllDates ? strings.feed : strings.dayFeed,
          periodLabel: feedPeriodLabel(context, view),
          filter: view.filter,
          filters: FeedFilter.values,
          onGoToToday: onGoToToday,
          onFilterSelected: onFilterSelected,
          onPickDate: dated ? onPickDate : null,
          onPrevious: dated ? () => onMovePeriod(-1) : null,
          onNext: dated ? () => onMovePeriod(1) : null,
        ),
        Expanded(
          child: FeedBody(
            allDates: view.allDates,
            filter: view.filter,
            layout: layout,
            loadState: loadState,
          ),
        ),
      ],
    );

    if (NotebookVisuals.maybeOf(context) == null) return content;
    return NotebookPageSurface(showLines: true, child: content);
  }
}
