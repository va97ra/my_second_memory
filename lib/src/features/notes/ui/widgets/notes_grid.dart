import 'dart:math' as math;

import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../../home_feed/home_feed.dart';
import 'note_grid_card.dart';
import 'notes_add_button.dart';

/// Сетка записок: квадратные карточки, на телефоне три в ряд. Выполненные лежат
/// ниже, под той же полосой, что в ленте.
class NotesGrid extends StatelessWidget {
  const NotesGrid({super.key, required this.notes, required this.hasQuery});

  /// Насколько плюс приподнят над низом окна.
  static const addButtonInset = 14.0;

  /// На широком экране ряд длиннее, чтобы карточки не вырастали во весь лист.
  static const _maxCardWidth = 180.0;
  static const _gap = 8.0;
  static const _edge = 12.0;

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
        final columns = math.max(3, constraints.maxWidth ~/ _maxCardWidth);
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

  Widget _grid(List<String> ids, int columns) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: _edge),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: _gap,
          crossAxisSpacing: _gap,
        ),
        itemCount: ids.length,
        itemBuilder: (context, index) => NoteGridCard(itemId: ids[index]),
      ),
    );
  }
}
