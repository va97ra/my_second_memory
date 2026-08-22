import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/notebook/notebook_background.dart';
import '../../../core/theme/notebook/notebook_visuals.dart';
import '../../../shared/ui/notebook_icon_button.dart';
import '../../../shared/ui/notebook_page_header.dart';
import '../../../shared/ui/notebook_pressable.dart';
import '../../../shared/ui/page_turn_frame.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../memory_items/state/memory_item_selectors.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../domain/feed_rules.dart';
import '../state/feed_providers.dart';
import 'widgets/memory_item_card.dart';

part 'widgets/feed_sections.dart';
part 'widgets/feed_guide.dart';
part 'widgets/feed_filter_button.dart';
part 'widgets/feed_section_tabs.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final GlobalKey<PageTurnFrameState> _pageTurnKey = GlobalKey();
  double _periodDragExtent = 0;

  @override
  Widget build(BuildContext context) {
    final loadState = ref.watch(memoryItemsLoadProvider);
    ref.watch(recurrenceLoadProvider);
    final view = ref.watch(feedViewProvider);
    final layout = ref.watch(feedLayoutProvider);
    final showHelp = ref.watch(appHintsProvider);
    final notebook = NotebookVisuals.maybeOf(context);

    return WarmGradientBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useSideTabs = notebook != null && constraints.maxHeight >= 360;
          final sheet = PageTurnFrame(
            key: _pageTurnKey,
            child: _FeedPage(
              view: view,
              layout: layout,
              loadState: loadState,
              showHelp: showHelp,
              alignToRuling: useSideTabs,
              onGoToToday: view.showsPeriodOf(DateTime.now())
                  ? null
                  : () => _goToToday(),
              onFilterSelected: (filter) =>
                  ref.read(feedViewProvider.notifier).selectFilter(filter),
              onMovePeriod: _movePeriod,
              onShowHelp: () => _showFullGuide(
                context,
                Localizations.localeOf(context).languageCode == 'ru',
              ),
            ),
          );
          // Pages are turned with a finger, not only with the arrows. Notes
          // have no period to move through, so they stay put.
          final page = view.section == FeedSection.notes
              ? sheet
              : GestureDetector(
                  key: const ValueKey('feed_period_swipe_area'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => _periodDragExtent = 0,
                  onHorizontalDragUpdate: (details) {
                    _periodDragExtent += details.primaryDelta ?? 0;
                  },
                  onHorizontalDragEnd: _finishPeriodSwipe,
                  onHorizontalDragCancel: () => _periodDragExtent = 0,
                  child: sheet,
                );

          if (!useSideTabs) {
            return Column(
              children: [
                _FeedTopSectionSelector(
                  selected: view.section,
                  onSelected: _selectSection,
                ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: page,
                  ),
                ),
              ],
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth.clamp(0, 760),
              height: constraints.maxHeight,
              child: _NotebookFeedBook(
                selected: view.section,
                onSelected: _selectSection,
                page: page,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectSection(FeedSection section) async {
    final current = ref.read(feedViewProvider).section;
    if (section == current) return;
    final frame = _pageTurnKey.currentState;
    void switchContent() {
      ref.read(feedViewProvider.notifier).selectSection(section);
    }

    if (frame == null) {
      switchContent();
      return;
    }
    await frame.beginTurn(
      direction: section.index > current.index
          ? PageTurnDirection.forward
          : PageTurnDirection.backward,
      switchContent: switchContent,
    );
  }

  void _finishPeriodSwipe(DragEndDetails details) {
    const distanceThreshold = 48.0;
    const velocityThreshold = 350.0;
    final velocity = details.primaryVelocity ?? 0;
    final distance = _periodDragExtent;
    _periodDragExtent = 0;

    // Dragging the sheet to the left carries it over the spine: that is the
    // next page.
    if (distance.abs() >= distanceThreshold) {
      unawaited(_movePeriod(distance < 0 ? 1 : -1));
      return;
    }
    if (velocity.abs() >= velocityThreshold) {
      unawaited(_movePeriod(velocity < 0 ? 1 : -1));
    }
  }

  Future<void> _goToToday() async {
    final view = ref.read(feedViewProvider);
    if (view.showsPeriodOf(DateTime.now())) return;
    final frame = _pageTurnKey.currentState;
    void switchContent() {
      ref.read(feedViewProvider.notifier).goToToday();
    }

    if (frame == null) {
      switchContent();
      return;
    }
    // Today is almost always behind the page on screen, so the sheet falls
    // back rather than turning forward.
    final now = DateTime.now();
    await frame.beginTurn(
      direction: view.anchorDate.isAfter(DateTime(now.year, now.month, now.day))
          ? PageTurnDirection.backward
          : PageTurnDirection.forward,
      switchContent: switchContent,
    );
  }

  Future<void> _movePeriod(int delta) async {
    if (delta == 0) return;
    final frame = _pageTurnKey.currentState;
    void switchContent() {
      ref.read(feedViewProvider.notifier).movePeriod(delta);
    }

    if (frame == null) {
      switchContent();
      return;
    }
    await frame.beginTurn(
      direction:
          delta > 0 ? PageTurnDirection.forward : PageTurnDirection.backward,
      switchContent: switchContent,
    );
  }
}

class _FeedPage extends StatelessWidget {
  const _FeedPage({
    required this.view,
    required this.layout,
    required this.loadState,
    required this.showHelp,
    required this.alignToRuling,
    required this.onGoToToday,
    required this.onFilterSelected,
    required this.onMovePeriod,
    required this.onShowHelp,
  });

  final FeedViewState view;
  final FeedLayout layout;
  final AsyncValue<void> loadState;
  final bool showHelp;
  final bool alignToRuling;
  final VoidCallback? onGoToToday;
  final ValueChanged<FeedFilter> onFilterSelected;
  final ValueChanged<int> onMovePeriod;
  final VoidCallback onShowHelp;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final content = Column(
      children: [
        _FeedHeader(
          title: _sectionTitle(context, view.section),
          periodLabel: _periodLabel(context, view),
          filter: view.filter,
          showHelp: showHelp,
          alignToRuling: alignToRuling,
          onGoToToday: onGoToToday,
          onFilterSelected: onFilterSelected,
          onPrevious:
              view.section == FeedSection.notes ? null : () => onMovePeriod(-1),
          onNext:
              view.section == FeedSection.notes ? null : () => onMovePeriod(1),
          onShowHelp: onShowHelp,
        ),
        Expanded(
          child: _FeedBody(
            section: view.section,
            filter: view.filter,
            layout: layout,
            loadState: loadState,
          ),
        ),
      ],
    );

    if (notebook == null) return content;
    return NotebookPageSurface(
      showLines: true,
      child: content,
    );
  }
}

class _FeedBody extends StatelessWidget {
  const _FeedBody({
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
            if (section == FeedSection.month || section == FeedSection.year)
              SliverToBoxAdapter(
                child: _FeedGroupDivider(
                  label: _groupLabel(context, section, group.period),
                ),
              ),
            _MemorySliverList(
              itemIds: group.itemIds,
              showDate: section == FeedSection.year,
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

String _sectionTitle(BuildContext context, FeedSection section) {
  final strings = AppStrings.of(context);
  return switch (section) {
    FeedSection.day => strings.dayFeed,
    FeedSection.month => strings.monthFeed,
    FeedSection.year => strings.yearFeed,
    FeedSection.notes => strings.notes,
  };
}

String? _periodLabel(BuildContext context, FeedViewState view) {
  if (view.section == FeedSection.notes) return null;
  final locale = Localizations.localeOf(context).languageCode;
  final formatted = switch (view.section) {
    FeedSection.day => DateFormat.yMMMMEEEEd(locale).format(view.anchorDate),
    FeedSection.month => DateFormat.yMMMM(locale).format(view.anchorDate),
    FeedSection.year => locale == 'ru'
        ? '${view.anchorDate.year} год'
        : '${view.anchorDate.year}',
    FeedSection.notes => '',
  };
  return _capitalize(formatted);
}

String _groupLabel(
  BuildContext context,
  FeedSection section,
  DateTime period,
) {
  final locale = Localizations.localeOf(context).languageCode;
  final value = section == FeedSection.year
      ? DateFormat.MMMM(locale).format(period)
      : DateFormat(locale == 'ru' ? 'd MMMM, EEEE' : 'EEEE, MMMM d', locale)
          .format(period);
  return _capitalize(value);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
