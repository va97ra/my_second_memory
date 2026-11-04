import 'dart:math' as math;

import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'note_grid_card.dart';
import 'notes_add_button.dart';

/// Сетка записок: квадратные карточки, на телефоне три в ряд.
class NotesGrid extends StatelessWidget {
  const NotesGrid({super.key, required this.itemIds, required this.hasQuery});

  /// Насколько плюс приподнят над низом окна.
  static const addButtonInset = 14.0;

  /// На широком экране ряд длиннее, чтобы карточки не вырастали во весь лист.
  static const _maxCardWidth = 180.0;
  static const _gap = 8.0;

  final List<String> itemIds;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    if (hasQuery && itemIds.isEmpty) {
      return Center(child: Text(AppStrings.of(context).feedNothingFound));
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        key: const ValueKey('notes_grid'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        // Снизу запас под плюс: последний ряд не должен лежать под ним.
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          NotesAddButton.size + addButtonInset * 2,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: math.max(3, constraints.maxWidth ~/ _maxCardWidth),
          mainAxisSpacing: _gap,
          crossAxisSpacing: _gap,
        ),
        itemCount: itemIds.length,
        itemBuilder: (context, index) => NoteGridCard(itemId: itemIds[index]),
      ),
    );
  }
}
