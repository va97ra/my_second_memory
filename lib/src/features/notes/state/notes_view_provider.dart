import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/memory_items.dart';

/// Что человек выбрал в окне записок: фильтр и поиск.
@immutable
class NotesViewState {
  const NotesViewState({
    this.filter = FeedFilter.all,
    this.searching = false,
    this.searchQuery = '',
  });

  final FeedFilter filter;
  final bool searching;

  /// Что ищут. Живёт только при открытом поиске.
  final String searchQuery;

  /// Ищет ли окно прямо сейчас: пустая строка ничего не ищет.
  bool get hasQuery => searching && !MemorySearch(searchQuery).isEmpty;

  NotesViewState copyWith({
    FeedFilter? filter,
    bool? searching,
    String? searchQuery,
  }) {
    return NotesViewState(
      filter: filter ?? this.filter,
      searching: searching ?? this.searching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class NotesViewController extends StateNotifier<NotesViewState> {
  NotesViewController() : super(const NotesViewState());

  /// Каждый вход в поиск начинается с пустой строки.
  void toggleSearch() =>
      state = state.copyWith(searching: !state.searching, searchQuery: '');

  void search(String query) {
    if (!state.searching) return;
    state = state.copyWith(searchQuery: query);
  }

  void selectFilter(FeedFilter filter) =>
      state = state.copyWith(filter: filter);
}

final notesViewProvider =
    StateNotifierProvider<NotesViewController, NotesViewState>(
  (ref) => NotesViewController(),
);

/// Какие фильтры предлагает окно записок: все, в работе, выполненные и только
/// те виды, что есть среди записок. Даты у записок нет, поэтому фильтров по
/// периоду здесь нет. Выбранный фильтр остаётся в списке, даже если записок
/// этого вида больше нет: иначе его не снять.
final notesFiltersProvider = Provider<List<FeedFilter>>((ref) {
  final types = {for (final item in ref.watch(undatedNotesProvider)) item.type};
  final selected = ref.watch(notesViewProvider.select((view) => view.filter));
  return [
    FeedFilter.all,
    FeedFilter.active,
    FeedFilter.done,
    for (final filter in FeedFilter.byMemoryType)
      if (types.contains(filter.memoryType) || filter == selected) filter,
  ];
});

/// Какие записки лежат в окне: в работе и выполненные. Окно держит только
/// идентификаторы, а саму запись каждая карточка читает из общего хранилища.
final notesIdsProvider =
    Provider<({List<String> active, List<String> done})>((ref) {
  final view = ref.watch(notesViewProvider);
  final search = MemorySearch(view.searchQuery);
  final notes = splitDoneItems(
    ref.watch(undatedNotesProvider).where(
          (item) =>
              matchesFeedFilter(item, view.filter) && search.matches(item),
        ),
    view.filter,
  );
  return (
    active: [for (final item in notes.active) item.id],
    done: [for (final item in notes.done) item.id],
  );
});
