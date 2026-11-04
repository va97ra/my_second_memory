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

/// Какие записки лежат в окне. Окно держит только идентификаторы, а саму
/// запись каждая карточка читает из общего хранилища.
final notesIdsProvider = Provider<List<String>>((ref) {
  final view = ref.watch(notesViewProvider);
  final search = MemorySearch(view.searchQuery);
  return [
    for (final item in ref.watch(undatedNotesProvider))
      if (matchesFeedFilter(item, view.filter) && search.matches(item)) item.id,
  ];
});
