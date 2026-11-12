import 'package:flutter/material.dart';

import 'sticker_paper.dart';

/// Ровные ряды одинаковых карточек обычным виджетом, а не частью прокрутки.
class EvenWrap extends StatelessWidget {
  const EvenWrap({
    super.key,
    required this.columns,
    required this.children,
    this.itemHeight,
  });

  /// Сколько карточек в ряду при этой ширине.
  final int Function(double width) columns;

  /// Высота карточки. Пусто — карточка квадратная.
  final double? itemHeight;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = StickerPaper.gridGap;
        final count = columns(constraints.maxWidth);
        final width = (constraints.maxWidth - gap * (count - 1)) / count;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                height: itemHeight ?? width,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
