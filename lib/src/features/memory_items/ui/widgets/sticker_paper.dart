import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_paper.dart';

/// Бумага карточки: ровный квадрат со скруглением, цветная полоса сверху.
class StickerPaper extends StatelessWidget {
  const StickerPaper({
    super.key,
    required this.accent,
    required this.strip,
    required this.child,
    this.lifted = false,
  });

  /// Высота цветной полосы с подписями.
  static const stripHeight = 18.0;
  static const _radius = BorderRadius.all(Radius.circular(8));

  final Color accent;
  final Widget strip;
  final Widget child;

  /// Карточку несут: тень от неё больше.
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return PaperSheet(
      child: Material(
        color: notebookCardSurface,
        elevation: lifted ? 10 : 3,
        shadowColor: MemoryCardPaper.shadowColor(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(color: accent.withValues(alpha: 0.34)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: MemoryCardPaper.surface(_radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: stripHeight, child: strip),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
