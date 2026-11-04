import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../../home_feed/home_feed.dart';
import '../../../memory_items/memory_items.dart';
import 'notes_add_button.dart';

/// Сетка записок: квадратные карточки, на телефоне три в ряд. Выполненные лежат
/// ниже, под той же полосой, что в ленте.
class NotesGrid extends StatelessWidget {
  const NotesGrid({super.key, required this.notes, required this.hasQuery});

  /// Насколько плюс приподнят над низом окна.
  static const addButtonInset = 14.0;


  final ({List<String> active, List<String> done}) notes;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (hasQuery && notes.active.isEmpty && notes.done.isEmpty) {
      return Center(child: Text(strings.feedNothingFound));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = memoryStickerColumns(constraints.maxWidth);
        return CustomScrollView(
          key: const ValueKey('notes_grid'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 8)),
            _grid(notes.active, columns),
            if (notes.done.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FeedGroupDivider(
                  key: const ValueKey('notes_done_divider'),
                  label: strings.completedRecords,
                ),
              ),
              _grid(notes.done, columns),
            ],
            // Запас под плюс: последний ряд не должен лежать под ним.
            const SliverPadding(
              padding: EdgeInsets.only(
                bottom: NotesAddButton.size + addButtonInset * 2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _grid(List<String> ids, int columns) => MemoryStickerGrid(
        itemIds: ids,
        columns: columns,
        stamp: StickerStamp.created,
        openQuery: '?panel=notes',
      );
}
