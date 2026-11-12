import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_paper.dart';

/// Бумага шкалы дней и подписи рядом с ней.
class FeedDayRailPaper extends StatelessWidget {
  const FeedDayRailPaper({
    super.key,
    required this.radius,
    required this.elevation,
    required this.child,
  });

  final BorderRadius radius;
  final double elevation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Спрашивают снаружи листа: внутри тема всегда светлая.
    final shadow = MemoryCardPaper.shadowColor(context);
    return PaperSheet(
      child: Material(
        color: notebookCardSurface,
        elevation: elevation,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
