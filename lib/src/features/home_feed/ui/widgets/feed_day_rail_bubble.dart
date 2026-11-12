import 'package:flutter/material.dart';

import 'feed_day_rail_paper.dart';

/// Полная дата рядом с пальцем: сам палец закрывает клетку шкалы.
class FeedDayRailBubble extends StatelessWidget {
  const FeedDayRailBubble({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FeedDayRailPaper(
      radius: BorderRadius.circular(8),
      elevation: 6,
      child: Builder(
        builder: (context) => Padding(
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
    );
  }
}
