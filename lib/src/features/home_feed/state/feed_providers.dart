import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';

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
    this.searching = false,
    this.searchQuery = '',
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

  /// Открыт ли поиск. Ищут в открытой закладке: на дне — среди записей всех
  /// дат, на записках — среди записок. Переход между закладками поиск не
  /// закрывает: тот же запрос просто ищется в другом месте.
  final bool searching;

  /// Что ищут. Живёт только при открытом поиске.
  final String searchQuery;

  /// Ищет ли лента прямо сейчас: поиск открыт и в строке есть хоть одно
  /// слово. Пустая строка ничего не ищет, и закладка показывает своё обычное
  /// содержимое — иначе прошлые находки казались бы застрявшими в списке.
  bool get hasQuery => searching && !MemorySearch(searchQuery).isEmpty;

  /// Лента дня показывает все даты разом, а не одну страницу: запрос на дне
  /// ищет по всем сохранённым записям, а не по открытому дню.
  bool get allDates => hasQuery && section == FeedSection.day;

  /// Whether the page on screen is the one holding [now]. Notes have no
  /// period, so they always count as current.
  bool showsPeriodOf(DateTime now) {
    if (section == FeedSection.notes || allDates) return true;
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
    bool? searching,
    String? searchQuery,
  }) {
    return FeedViewState(
      section: section ?? this.section,
      anchorDate: anchorDate ?? this.anchorDate,
      filter: filter ?? this.filter,
      searching: searching ?? this.searching,
      searchQuery: searchQuery ?? this.searchQuery,
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

  /// Открывает и закрывает поиск. Каждый вход начинается с пустой строки:
  /// прошлый запрос, всплывший сам, выглядел бы как пропавшие записи.
  void toggleSearch() =>
      state = state.copyWith(searching: !state.searching, searchQuery: '');

  void search(String query) {
    if (!state.searching || query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
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
    // Пока открыт поиск, период закрыт строкой запроса: листать вслепую
    // нельзя.
    if (delta == 0 || state.section == FeedSection.notes || state.searching) {
      return;
    }
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
    if (state.section == FeedSection.day &&
        state.anchorDate == day &&
        !state.searching) {
      return;
    }
    state = state.copyWith(
      section: FeedSection.day,
      anchorDate: day,
      searching: false,
      searchQuery: '',
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
