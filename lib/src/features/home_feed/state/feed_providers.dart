import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import '../../memory_items/memory_items.dart';
import '../../recurrence/recurrence.dart';

/// Закладки ленты.
///
/// Лента листается по дням; месяц и год — это не разновидность записи, а
/// масштаб, за которым ходят в календарь. Повторы отбираются фильтром
/// [FeedFilter.recurring], а не отдельной закладкой.
enum FeedSection { day, notes }

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
    if (section == FeedSection.notes) return true;
    // Фильтр повторов раскрывает ленту на месяц или на год, поэтому текущей
    // считается страница этого периода, а не одного дня.
    return switch (filter.recurringFrequency) {
      null => anchorDate.year == now.year &&
          anchorDate.month == now.month &&
          anchorDate.day == now.day,
      RecurrenceFrequency.monthly =>
        anchorDate.year == now.year && anchorDate.month == now.month,
      RecurrenceFrequency.yearly => anchorDate.year == now.year,
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
    // Записка не повторяется, поэтому фильтр повторов на её закладке всегда
    // показывал бы пустую страницу. Закладка возвращает фильтр к обычному.
    final keepsFilter =
        section != FeedSection.notes || state.filter.recurringFrequency == null;
    state = state.copyWith(
      section: section,
      filter: keepsFilter ? state.filter : FeedFilter.all,
    );
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
    // Шаг листания равен показанному периоду: день, месяц или год.
    final next = switch (state.filter.recurringFrequency) {
      null => DateTime(anchor.year, anchor.month, anchor.day + delta),
      RecurrenceFrequency.monthly => _shiftMonth(anchor, delta),
      RecurrenceFrequency.yearly => _shiftYear(anchor, delta),
    };
    state = state.copyWith(anchorDate: next);
  }

  /// Переход на конкретный день. Записки не привязаны к дате, поэтому выбор
  /// дня переводит ленту на дневную закладку.
  void selectDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (state.section == FeedSection.day && state.anchorDate == day) return;
    state = state.copyWith(section: FeedSection.day, anchorDate: day);
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
    if (state.section == FeedSection.notes) {
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
  // Вкладка задаёт период, а не разновидность записи: день, месяц и год
  // показывают всё, что в них попадает. Повторы отбираются фильтром
  // FeedFilter.recurring, а не тем, на какой вкладке стоит читатель.
  final itemsByDate = ref.watch(memoryItemsByDateProvider);
  final persisted = <MemoryItem>[];
  for (var day = start;
      !day.isAfter(end);
      day = DateTime(day.year, day.month, day.day + 1)) {
    persisted.addAll(itemsByDate[memoryItemDateKey(day)] ?? const []);
  }
  // Проекция уже пропускает даты, у которых есть сохранённая запись, поэтому
  // два источника не спорят между собой.
  final source = [
    ...persisted,
    ...ref.watch(recurrenceItemsForRangeProvider(RecurrenceRange(start, end))),
  ];
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
      FeedSection.notes => query.anchorDate,
      FeedSection.day =>
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
