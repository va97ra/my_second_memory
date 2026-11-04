import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../home_feed/home_feed.dart';
import '../../memory_items/memory_items.dart';
import '../state/notes_view_provider.dart';
import 'widgets/notes_add_button.dart';
import 'widgets/notes_grid.dart';

/// Окно записок: та же шапка, что у ленты, под ней карточки, внизу плюс.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final loadState = ref.watch(memoryItemsLoadProvider);
    final view = ref.watch(notesViewProvider);
    final controller = ref.read(notesViewProvider.notifier);

    final content = Column(
      children: [
        FeedHeader(
          hint: strings.notesPageHint,
          searching: view.searching,
          searchHint: strings.searchNotes,
          onToggleSearch: controller.toggleSearch,
          searchQuery: view.searchQuery,
          onSearch: controller.search,
          title: strings.notes,
          periodLabel: null,
          filter: view.filter,
          filters: ref.watch(notesFiltersProvider),
          onGoToToday: null,
          onFilterSelected: controller.selectFilter,
          onPickDate: null,
          onPrevious: null,
          onNext: null,
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (loadState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (loadState.hasError)
                Center(child: Text(strings.loadFailed))
              else
                NotesGrid(
                  notes: ref.watch(notesIdsProvider),
                  hasQuery: view.hasQuery,
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: NotesGrid.addButtonInset,
                child: Center(
                  child: NotesAddButton(
                    onPressed: () => context.pageTurnPush('/memory/note/new'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return FeedPageShell(
      page: NotebookVisuals.maybeOf(context) == null
          ? content
          : NotebookPageSurface(showLines: false, child: content),
    );
  }
}
