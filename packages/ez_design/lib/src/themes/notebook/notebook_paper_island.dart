import 'package:flutter/material.dart';

import '../../tokens/content_typography.dart';
import 'notebook_theme.dart';
import 'notebook_visuals.dart';

/// The light notebook, built once, for the loose paper lying on the dark one.
final ThemeData _lightNotebook =
    buildNotebookTheme(brightness: Brightness.light);

/// Loose paper lying on the book.
///
/// A memory card and a calendar day cell stay light in both themes, so
/// everything drawn inside one has to read the light notebook's scheme rather
/// than the dark page's: ink stays dark, borders stay warm, the grain stays
/// light stock. Without this the card would be a light rectangle full of pale
/// text meant for a dark page.
///
/// The reader's chosen record font is carried across, since it belongs to them
/// rather than to the theme.
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
    final content = theme.extension<AppContentTypography>();
    return Theme(
      data: content == null
          ? _lightNotebook
          : _lightNotebook.copyWith(
              extensions: [..._lightNotebook.extensions.values, content],
            ),
      child: child,
    );
  }
}
