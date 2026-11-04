import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'notebook_feed_book.dart';

/// Где лежит страница ленты или записок: в блокноте — в книге, в остальных
/// темах — прямо на заднике, до самой нижней панели.
class FeedPageShell extends StatelessWidget {
  const FeedPageShell({super.key, required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);

    return WarmGradientBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (notebook == null || constraints.maxHeight < 360) {
            return MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: page,
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth.clamp(0, 760),
              height: constraints.maxHeight,
              child: NotebookFeedBook(page: page),
            ),
          );
        },
      ),
    );
  }
}
