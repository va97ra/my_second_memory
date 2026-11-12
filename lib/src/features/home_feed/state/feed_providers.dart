import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:ez_domain/ez_domain.dart';

@immutable
class FeedViewState {
  const FeedViewState({
    required this.anchorDate,
    required this.filter,
    this.search = const MemorySearchBar(),
  });

  factory FeedViewState.initial() {
    final now = DateTime.now();
    return FeedViewState(
      anchorDate: DateTime(now.year, now.month, now.day),
      filter: FeedFilter.day,
    );
  }

  final DateTime anchorDate;
  final FeedFilter filter;

  /// Строка поиска. Ищет она по всем датам.
  final MemorySearchBar search;

  bool get searching => search.isOpen;
  String get searchQuery => search.query;
  bool get hasQuery => search.hasQuery;

  /// Фильтр раскрыл ленту на все даты: всё, кроме «Дня» и повторов.
  bool get filterSpansAllDates => !filter.isPeriodBound;

  /// Лента показывает все даты разом, а не одну страницу: так работают поиск
  /// и фильтры, не привязанные к периоду.
  bool get allDates => hasQuery || filterSpansAllDates;

  /// Whether the page on screen is the one holding [now].
  bool showsPeriodOf(DateTime now) {
    if (hasQuery) return true;
    // Со всех дат кнопка «сегодня» возвращает на страницу дня.
    if (filterSpansAllDates) return false;
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
    DateTime? anchorDate,
    FeedFilter? filter,
    MemorySearchBar? search,
  }) {
    return FeedViewState(
      anchorDate: anchorDate ?? this.anchorDate,
      filter: filter ?? this.filter,
      search: search ?? this.search,
    );
  }
}

class FeedViewController extends StateNotifier<FeedViewState> {
  FeedViewController({FeedViewState? initialState})
      : super(initialState ?? FeedViewState.initial());

  /// Фильтр, с которым можно показать один день.
  FeedFilter get _filterForOneDay =>
      state.filterSpansAllDates ? FeedFilter.day : state.filter;

  void toggleSearch() => state = state.copyWith(search: state.search.toggled());

  void search(String query) =>
      state = state.copyWith(search: state.search.withQuery(query));

  void selectFilter(FeedFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
  }

  /// Returns the anchor to today; a filter spanning all dates gives way to
  /// the day page, since that is what the button promises.
  void goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filter = _filterForOneDay;
    if (state.anchorDate == today && filter == state.filter) return;
    state = state.copyWith(anchorDate: today, filter: filter);
  }

  void movePeriod(int delta) {
    // Пока открыт поиск, период закрыт строкой запроса: листать вслепую
    // нельзя.
    if (delta == 0 || state.searching || state.allDates) return;
    final anchor = state.anchorDate;
    // Шаг листания равен показанному периоду: день, месяц или год.
    final next = switch (state.filter.recurringFrequency) {
      null => DateTime(anchor.year, anchor.month, anchor.day + delta),
      RecurrenceFrequency.monthly => _shiftMonth(anchor, delta),
      RecurrenceFrequency.yearly => _shiftYear(anchor, delta),
    };
    state = state.copyWith(anchorDate: next);
  }

  /// Переход на конкретный день; открытый поиск при этом закрывается.
  void selectDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final filter = _filterForOneDay;
    if (state.anchorDate == day &&
        filter == state.filter &&
        !state.searching) {
      return;
    }
    state = state.copyWith(
      anchorDate: day,
      filter: filter,
      search: const MemorySearchBar(),
    );
  }
}

final feedViewProvider =
    StateNotifierProvider<FeedViewController, FeedViewState>(
  (ref) => FeedViewController(),
);

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
