import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_item_selectors.dart';
import '../../recurrence/domain/recurrence_series.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../domain/feed_rules.dart';

enum FeedSection { day, month, year, notes }

@immutable
class FeedViewState {
  const FeedViewState({
    required this.section,
    required this.anchorDate,
    required this.filter,
  });

  factory FeedViewState.initial() {
    final now = DateTime.now();
    return FeedViewState(
      section: FeedSection.day,
      anchorDate: DateTime(now.year, now.month, now.day),
      filter: FeedFilter.all,
    );
  }

  final FeedSection section;
  final DateTime anchorDate;
  final FeedFilter filter;

  /// Whether the page on screen is the one holding [now]. Notes have no
  /// period, so they always count as current.
  bool showsPeriodOf(DateTime now) {
    return switch (section) {
      FeedSection.day => anchorDate.year == now.year &&
          anchorDate.month == now.month &&
          anchorDate.day == now.day,
      FeedSection.month =>
        anchorDate.year == now.year && anchorDate.month == now.month,
      FeedSection.year => anchorDate.year == now.year,
      FeedSection.notes => true,
    };
  }

  FeedViewState copyWith({
    FeedSection? section,
    DateTime? anchorDate,
    FeedFilter? filter,
  }) {
    return FeedViewState(
      section: section ?? this.section,
      anchorDate: anchorDate ?? this.anchorDate,
      filter: filter ?? this.filter,
    );
  }
}

class FeedViewController extends StateNotifier<FeedViewState> {
  FeedViewController({FeedViewState? initialState})
      : super(initialState ?? FeedViewState.initial());

  void selectSection(FeedSection section) {
    if (section == state.section) return;
    state = state.copyWith(section: section);
  }

  void selectFilter(FeedFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
  }

  /// Returns the anchor to today without leaving the current section.
  void goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (state.anchorDate == today) return;
    state = state.copyWith(anchorDate: today);
  }

  void movePeriod(int delta) {
    if (delta == 0 || state.section == FeedSection.notes) return;
    final anchor = state.anchorDate;
    final next = switch (state.section) {
      FeedSection.day => anchor.add(Duration(days: delta)),
      FeedSection.month => _shiftMonth(anchor, delta),
      FeedSection.year => _shiftYear(anchor, delta),
      FeedSection.notes => anchor,
    };
    state = state.copyWith(anchorDate: next);
  }
}

final feedViewProvider =
    StateNotifierProvider<FeedViewController, FeedViewState>(
  (ref) => FeedViewController(),
);

@immutable
class FeedPeriodQuery {
  const FeedPeriodQuery({
    required this.section,
    required this.anchorDate,
    this.start,
    this.end,
  });

  factory FeedPeriodQuery.fromState(FeedViewState state) {
    final anchor = _dateOnly(state.anchorDate);
    return switch (state.section) {
      FeedSection.day => FeedPeriodQuery(
          section: state.section,
          anchorDate: anchor,
          start: anchor,
          end: anchor,
        ),
      FeedSection.month => FeedPeriodQuery(
          section: state.section,
          anchorDate: anchor,
          start: DateTime(anchor.year, anchor.month),
          end: DateTime(anchor.year, anchor.month + 1, 0),
        ),
      FeedSection.year => FeedPeriodQuery(
          section: state.section,
          anchorDate: anchor,
          start: DateTime(anchor.year),
          end: DateTime(anchor.year, 12, 31),
        ),
      FeedSection.notes => FeedPeriodQuery(
          section: state.section,
          anchorDate: anchor,
        ),
    };
  }

  final FeedSection section;
  final DateTime anchorDate;
  final DateTime? start;
  final DateTime? end;
}

@immutable
class FeedLayout {
  const FeedLayout({required this.query, required this.groups});

  final FeedPeriodQuery query;
  final List<FeedGroupLayout> groups;

  List<String> get itemIds => [
        for (final group in groups) ...group.itemIds,
      ];
}

@immutable
class FeedGroupLayout {
  const FeedGroupLayout({required this.period, required this.itemIds});

  final DateTime period;
  final List<String> itemIds;
}

final feedLayoutProvider = Provider<FeedLayout>((ref) {
  final state = ref.watch(feedViewProvider);
  final query = FeedPeriodQuery.fromState(state);

  if (state.section == FeedSection.notes) {
    final notes = ref
        .watch(undatedNotesProvider)
        .where((item) => matchesFeedFilter(item, state.filter))
        .toList(growable: false);
    return FeedLayout(
      query: query,
      groups: [
        if (notes.isNotEmpty)
          FeedGroupLayout(
            period: query.anchorDate,
            itemIds: [for (final item in notes) item.id],
          ),
      ],
    );
  }

  final start = query.start!;
  final end = query.end!;
  final source = switch (state.section) {
    FeedSection.day => [
        for (final item
            in ref.watch(memoryItemsByDateProvider)[memoryItemDateKey(start)] ??
                const <MemoryItem>[])
          if (!_isRecurringItem(item)) item,
      ],
    FeedSection.month || FeedSection.year => ref.watch(
        recurringItemsForPeriodProvider(
          RecurrencePeriod(
            frequency: state.section == FeedSection.month
                ? RecurrenceFrequency.monthly
                : RecurrenceFrequency.yearly,
            start: start,
            end: end,
          ),
        ),
      ),
    FeedSection.notes => const <MemoryItem>[],
  };
  final byId = <String, MemoryItem>{};
  for (final item in source) {
    if (item.isUndated || item.isArchived) continue;
    final date = _dateOnly(item.memoryDate);
    if (date.isBefore(start) || date.isAfter(end)) continue;
    if (!matchesFeedFilter(item, state.filter)) continue;
    byId[item.id] = item;
  }

  final items = byId.values.toList()..sort(_compareDatedItems);
  final grouped = <DateTime, List<String>>{};
  for (final item in items) {
    final period = switch (state.section) {
      FeedSection.year => DateTime(item.memoryDate.year, item.memoryDate.month),
      FeedSection.day || FeedSection.month => _dateOnly(item.memoryDate),
      FeedSection.notes => query.anchorDate,
    };
    grouped.putIfAbsent(period, () => <String>[]).add(item.id);
  }

  return FeedLayout(
    query: query,
    groups: [
      for (final entry in grouped.entries)
        FeedGroupLayout(period: entry.key, itemIds: entry.value),
    ],
  );
});

bool _isRecurringItem(MemoryItem item) {
  final repeatRule = item.repeatRule?.trim().toLowerCase();
  return item.seriesId != null ||
      repeatRule == RecurrenceFrequency.monthly.name ||
      repeatRule == RecurrenceFrequency.yearly.name;
}

int _compareDatedItems(MemoryItem left, MemoryItem right) {
  final byDate =
      _dateOnly(left.memoryDate).compareTo(_dateOnly(right.memoryDate));
  if (byDate != 0) return byDate;
  final leftTime = left.timeMinutes;
  final rightTime = right.timeMinutes;
  if (leftTime != null || rightTime != null) {
    if (leftTime == null) return 1;
    if (rightTime == null) return -1;
    final byTime = leftTime.compareTo(rightTime);
    if (byTime != 0) return byTime;
  }
  final byPriority = right.priority.compareTo(left.priority);
  if (byPriority != 0) return byPriority;
  return left.createdAt.compareTo(right.createdAt);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _shiftMonth(DateTime anchor, int delta) {
  final first = DateTime(anchor.year, anchor.month + delta);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, anchor.day.clamp(1, lastDay));
}

DateTime _shiftYear(DateTime anchor, int delta) {
  final year = anchor.year + delta;
  final lastDay = DateTime(year, anchor.month + 1, 0).day;
  return DateTime(year, anchor.month, anchor.day.clamp(1, lastDay));
}
