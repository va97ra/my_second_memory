import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../state/feed_providers.dart';
import 'notebook_section_tabs.dart';

/// Блокнот в блокнотной теме: обложка, лист с лентой и закладки снизу.
class NotebookFeedBook extends StatelessWidget {
  const NotebookFeedBook({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.page,
  });

  /// Высота полосы закладок под листом.
  static const double tabHeight = 52;

  final FeedSection selected;
  final ValueChanged<FeedSection> onSelected;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context)!;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        // Задняя обложка.
        Positioned(
          left: 12,
          right: 14,
          top: 12,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                const Color(0x1F7A4A22),
                notebook.paper,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x557A4A22)),
            ),
          ),
        ),
        // Стопка листов под текущим.
        Positioned(
          left: 7,
          right: 20,
          top: 7,
          bottom: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: notebook.paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x667A4A22)),
            ),
          ),
        ),
        Positioned(
          left: 4,
          right: 4,
          top: 3,
          bottom: tabHeight,
          child: SizedBox.expand(
            key: const ValueKey('notebook_feed_sheet'),
            child: page,
          ),
        ),
        // Тень у корешка.
        Positioned(
          left: 4,
          top: 3,
          bottom: tabHeight,
          width: 14,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          right: 4,
          bottom: 8,
          height: tabHeight,
          child: NotebookSectionTabs(
            selected: selected,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }
}
