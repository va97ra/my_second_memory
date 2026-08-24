import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../state/feed_providers.dart';
import '../feed_labels.dart';
import 'notebook_tab_shadowed_edge.dart';

/// Закладка блокнота. Выбранная выдвигается из книги и ложится поверх листа.
class NotebookIndexTab extends StatelessWidget {
  const NotebookIndexTab({
    super.key,
    required this.section,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final FeedSection section;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context)!;
    final base = switch (section) {
      FeedSection.day => notebook.yellow,
      FeedSection.notes => notebook.teal,
    };
    final edgeColor =
        selected ? const Color(0xFF8B542D) : const Color(0x996D4528);

    return Semantics(
      button: true,
      selected: selected,
      label: feedSectionTabLabel(context, section),
      child: SizedBox(
        key: ValueKey('feed_section_${section.name}'),
        height: 52,
        child: Align(
          alignment: Alignment.bottomCenter,
          // Бумага не отзывается волной. Нажатие выдвигает закладку из книги.
          child: NotebookPressable(
            onTap: selected ? null : onPressed,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(7),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: selected ? 52 : 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  base.withValues(alpha: selected ? 0.14 : 0.34),
                  notebook.paper,
                ),
                image: DecorationImage(
                  image: AssetImage(notebook.paperAsset),
                  fit: BoxFit.cover,
                  opacity: 0.55,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                // Одного видимого цвета границы достаточно, и только с ним
                // граница рисуется вместе со скруглением.
                border: Border(
                  left: BorderSide(color: edgeColor, width: 0.8),
                  top: BorderSide.none,
                  right: BorderSide(color: edgeColor, width: 0.8),
                  bottom: BorderSide(color: edgeColor, width: 0.8),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!selected) const NotebookTabShadowedEdge(),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4, selected ? 8 : 0, 4, 0),
                      child: Text(
                        feedSectionTabLabel(context, section, compact: compact),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: notebook.ink,
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
