import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../memory_items/state/memory_item_selectors.dart';
import '../../recurrence/ui/recurring_informers.dart';
import '../domain/feed_rules.dart';
import '../state/feed_providers.dart';
import 'widgets/memory_item_card.dart';

part 'widgets/feed_sections.dart';
part 'widgets/feed_guide.dart';
part 'widgets/feed_filter_button.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  static const _dividerHeight = 48.0;

  final Set<String> _expandedPastDays = <String>{};
  final ScrollController _scrollController = ScrollController();
  bool _notesExpanded = false;
  bool _initialTodayFocusScheduled = false;
  bool _branchWasActive = false;
  int _futureDayCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final branchIsActive = TickerMode.valuesOf(context).enabled;
    if (branchIsActive && !_branchWasActive && _initialTodayFocusScheduled) {
      _scheduleTodayFocus(force: true);
    }
    _branchWasActive = branchIsActive;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final loadState = ref.watch(memoryItemsLoadProvider);
    final filter = ref.watch(feedFilterProvider);
    final layout = ref.watch(feedLayoutProvider);
    final notes = ref.watch(undatedNotesProvider);
    final isEmpty = layout.days.isEmpty && notes.isEmpty;
    final showHints = ref.watch(appHintsProvider);
    final mediaQuery = MediaQuery.of(context);
    final showFeedHint = showHints &&
        mediaQuery.size.height >= 720 &&
        mediaQuery.textScaler.scale(1) <= 1.3;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final futureDayCount = layout.days.where((group) {
      final date = DateTime(group.date.year, group.date.month, group.date.day);
      return date.isAfter(today);
    }).length;
    _futureDayCount = futureDayCount;

    if (loadState.isLoading || loadState.hasError) {
      return WarmGradientBackground(
        child: CustomScrollView(
          slivers: [
            MainSliverAppBar(title: strings.dayFeed),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: loadState.isLoading
                    ? const CircularProgressIndicator()
                    : Text(strings.loadFailed),
              ),
            ),
          ],
        ),
      );
    }

    _scheduleTodayFocus();

    return WarmGradientBackground(
      child: Column(
        children: [
          _FeedHeader(
            title: strings.dayFeed,
            filter: filter,
            onFilterSelected: (filter) {
              ref.read(feedFilterProvider.notifier).state = filter;
            },
          ),
          if (showFeedHint) const _FeedUsageHint(),
          const KeyedSubtree(
            key: ValueKey('feed_recurring_informers'),
            child: RecurringInformers(height: 164),
          ),
          _FeedDayDivider(
            key: const ValueKey('feed_notes_divider'),
            label: '${strings.notes} · ${notes.length}',
            expanded: _notesExpanded,
            collapsible: true,
            onTap: _toggleNotes,
          ),
          if (_notesExpanded)
            _UndatedNotesList(itemIds: [
              for (final note in notes) note.id,
            ]),
          Expanded(
            child: CustomScrollView(
              key: const ValueKey('feed_dated_scroll'),
              controller: _scrollController,
              slivers: [
                if (isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppEmptyState(
                        icon: Icons.view_agenda_rounded,
                        title: strings.emptyFeed,
                        actionLabel: strings.addRecord,
                        onAction: () => context.go('/calendar'),
                      ),
                    ),
                  )
                else
                  for (final group in layout.days)
                    ..._buildDaySlivers(
                      context,
                      date: group.date,
                      itemIds: group.itemIds,
                    ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: futureDayCount > 0
                        ? MediaQuery.sizeOf(context).height
                        : 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleTodayFocus({bool force = false}) {
    if (_initialTodayFocusScheduled && !force) return;
    _initialTodayFocusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _futureDayCount * _dividerHeight;
      final position = _scrollController.position;
      _scrollController.jumpTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }

  void _toggleNotes() {
    setState(() => _notesExpanded = !_notesExpanded);
  }

  List<Widget> _buildDaySlivers(
    BuildContext context, {
    required DateTime date,
    required List<String> itemIds,
  }) {
    final key = _feedDateKey(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checked = DateTime(date.year, date.month, date.day);
    final isToday = checked == today;
    final isExpanded = isToday || _expandedPastDays.contains(key);
    final strings = AppStrings.of(context);
    final dateLabel = _feedDividerLabel(context, date);
    final label = isToday
        ? dateLabel
        : '$dateLabel · ${strings.recordsCount(itemIds.length)}';

    return [
      SliverToBoxAdapter(
        child: _FeedDayDivider(
          key: ValueKey('feed_day_divider_$key'),
          label: label,
          expanded: isExpanded,
          collapsible: !isToday,
          onTap: isToday
              ? null
              : () {
                  setState(() {
                    if (isExpanded) {
                      _expandedPastDays.remove(key);
                    } else {
                      _expandedPastDays.add(key);
                    }
                  });
                },
        ),
      ),
      if (isExpanded) _MemorySliverList(itemIds: itemIds),
    ];
  }
}
