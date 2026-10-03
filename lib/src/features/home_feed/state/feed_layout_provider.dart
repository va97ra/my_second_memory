import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import '../../memory_items/memory_items.dart';
import '../../recurrence/recurrence.dart';
import 'feed_providers.dart';

// Что лежит на странице ленты: какой период открыт и какие записи в него
// попали. Выбор человека — закладка, день, фильтр и запрос — живёт рядом, в
// `feed_providers.dart`; отсюда только раскладка по этому выбору.

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
    if (state.section == FeedSection.notes || state.allDates) {
      return FeedPeriodQuery(section: state.section, anchorDate: anchor);
    }
    // Обычная лента показывает один день. Фильтр повторов раскрывает её на
    // тот период, в котором повтор вообще случается.
    return switch (state.filter.recurringFrequency) {
      null => FeedPeriodQuery(
          section: state.section,
          anchorDate: anchor,
          start: anchor,
          end: anchor,
        ),
      RecurrenceFrequency.monthly => FeedPeriodQuery(
          section: state.section,
          anchorDate: anchor,
          start: DateTime(anchor.year, anchor.month),
          end: DateTime(anchor.year, anchor.month + 1, 0),
        ),
      RecurrenceFrequency.yearly => FeedPeriodQuery(
          section: state.section,
          anchorDate: anchor,
          start: DateTime(anchor.year),
          end: DateTime(anchor.year, 12, 31),
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

  final search = MemorySearch(state.searchQuery);
  if (state.section == FeedSection.notes) {
    final notes = ref
        .watch(undatedNotesProvider)
        .where((item) =>
            matchesFeedFilter(item, state.filter) && search.matches(item))
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

  final start = query.start;
  final end = query.end;
  final source = <MemoryItem>[];
  if (state.allDates) {
    source.addAll(ref.watch(memoryItemsControllerProvider));
  } else {
    final itemsByDate = ref.watch(memoryItemsByDateProvider);
    for (var day = start!;
        !day.isAfter(end!);
        day = DateTime(day.year, day.month, day.day + 1)) {
      source.addAll(itemsByDate[dateKey(day)] ?? const []);
    }
    source.addAll(ref
        .watch(recurrenceItemsForRangeProvider(RecurrenceRange(start, end))));
  }
  final byId = <String, MemoryItem>{};
  for (final item in source) {
    if (item.isUndated || item.isArchived) continue;
    final date = _dateOnly(item.memoryDate);
    if (start != null && (date.isBefore(start) || date.isAfter(end!))) continue;
    if (!matchesFeedFilter(item, state.filter)) continue;
    if (!search.matches(item)) continue;
    byId[item.id] = item;
  }

  final items = byId.values.toList()..sort(_compareDatedItems);
  final grouped = <DateTime, List<String>>{};
  for (final item in items) {
    final period = switch (state.section) {
      FeedSection.notes => query.anchorDate,
      FeedSection.day => !state.allDates &&
              state.filter.recurringFrequency == RecurrenceFrequency.yearly
          ? DateTime(item.memoryDate.year, item.memoryDate.month)
          : _dateOnly(item.memoryDate),
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
