import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_paper.dart';

/// Полная дата рядом с пальцем: сам палец закрывает клетку шкалы.
class FeedDayRailBubble extends StatelessWidget {
  const FeedDayRailBubble({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final shadow = MemoryCardPaper.shadowColor(context);
    return PaperSheet(
      child: Builder(
        builder: (context) => Material(
          color: notebookCardSurface,
          elevation: 6,
          shadowColor: shadow,
          surfaceTintColor: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
