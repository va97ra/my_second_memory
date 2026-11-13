import 'package:flutter/material.dart';

import 'notebook/loose_paper_theme.dart';
import 'notebook/notebook_visuals.dart';

/// Лист бумаги внутри любой темы.
///
/// Где по смыслу пишут — запись в ленте, записка, редактор, — там бумага:
/// светлая, с зерном, с линейкой и чёрными чернилами. Это свойство самой
/// вещи, а не оформления: в тёмной теме лист не становится чёрным, он просто
/// лежит на тёмном столе. Правило записано в `docs/layout.md`.
///
/// Внутри листа действует схема светлого блокнота, поэтому всё, что нарисовано
/// в нём, само берёт чернила, границы и линейку бумаги — их не нужно
/// передавать вниз по одному.
///
/// Шрифт содержимого и выбранные цвета переносятся через границу: они
/// принадлежат читателю, а не теме.
class PaperSheet extends StatelessWidget {
  const PaperSheet({required this.child, super.key});

  final Widget child;

  /// Была ли страница под листом блокнотной.
  ///
  /// Внутри листа спрашивать об этом [NotebookVisuals] бесполезно: там всегда
  /// блокнот, потому что бумага им и нарисована. А форма листа от страницы
  /// зависит — в блокноте он вырван из тетради, в остальных темах ровный.
  static bool pageIsNotebook(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PaperPage>()?.notebook ??
        NotebookVisuals.maybeOf(context) != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notebook = theme.extension<NotebookVisuals>() != null;
    if (notebook && theme.brightness == Brightness.light) {
      return _PaperPage(notebook: true, child: child);
    }
    return _PaperPage(
      notebook: notebook,
      child: Theme(data: loosePaperTheme(theme), child: child),
    );
  }
}

class _PaperPage extends InheritedWidget {
  const _PaperPage({required this.notebook, required super.child});

  final bool notebook;

  @override
  bool updateShouldNotify(_PaperPage oldWidget) =>
      oldWidget.notebook != notebook;
}
