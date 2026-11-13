import 'package:flutter/material.dart';

import 'loose_paper_theme.dart';
import 'notebook_visuals.dart';

/// Loose paper lying on the book.
///
/// A memory card and a calendar day cell stay light in both themes, so
/// everything drawn inside one has to read the light notebook's scheme rather
/// than the dark page's: ink stays dark, borders stay warm, the grain stays
/// light stock. Without this the card would be a light rectangle full of pale
/// text meant for a dark page.
///
/// The reader's chosen record font and colours are carried across, since they
/// belong to them rather than to the theme.
class NotebookPaperIsland extends StatelessWidget {
  const NotebookPaperIsland({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.extension<NotebookVisuals>() == null ||
        theme.brightness == Brightness.light) {
      return child;
    }
    return Theme(data: loosePaperTheme(theme), child: child);
  }
}
