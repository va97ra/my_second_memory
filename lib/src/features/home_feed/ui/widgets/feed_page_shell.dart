import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Где лежит страница ленты или записок: прямо на заднике, до самой нижней панели.
/// На широком экране страница не растягивается во весь экран.
class FeedPageShell extends StatelessWidget {
  const FeedPageShell({super.key, required this.page});

  final Widget page;

  @override
  Widget build(BuildContext context) {
    return WarmGradientBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth.clamp(0, 760),
              height: constraints.maxHeight,
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: page,
              ),
            ),
          );
        },
      ),
    );
  }
}
