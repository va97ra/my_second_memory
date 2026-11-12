import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/even_wrap.dart';
import '../../../../shared/ui/memory_card/sticker_paper.dart';
import 'memory_sticker.dart';
import 'sticker_carry.dart';

/// Сколько карточек в ряду: на телефоне три, на широком экране ряд длиннее, чтобы
/// карточки не вырастали во весь лист.
int memoryStickerColumns(double width) => math.max(3, width ~/ 180);

/// Ряды карточек внутри прокрутки: одно и то же в ленте и в записках.
class MemoryStickerGrid extends StatelessWidget {
  const MemoryStickerGrid({
    super.key,
    required this.itemIds,
    required this.columns,
    required this.stamp,
    this.openQuery = '',
    this.carry,
  });

  final List<String> itemIds;
  final int columns;
  final StickerStamp stamp;
  final String openQuery;
  final StickerCarry? carry;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: StickerPaper.gridEdge,
        vertical: 4,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: StickerPaper.gridGap,
          crossAxisSpacing: StickerPaper.gridGap,
        ),
        itemCount: itemIds.length,
        itemBuilder: (context, index) => MemorySticker(
          itemId: itemIds[index],
          stamp: stamp,
          openQuery: openQuery,
          carry: carry,
        ),
      ),
    );
  }
}

/// Те же ряды, но обычным виджетом, а не частью прокрутки.
class MemoryStickerWrap extends StatelessWidget {
  const MemoryStickerWrap({
    super.key,
    required this.itemIds,
    required this.columns,
    required this.stamp,
    this.carry,
  });

  final List<String> itemIds;
  final int columns;
  final StickerStamp stamp;
  final StickerCarry? carry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StickerPaper.gridEdge,
        vertical: 4,
      ),
      child: EvenWrap(
        columns: (_) => columns,
        children: [
          for (final id in itemIds)
            MemorySticker(
              key: ValueKey(id),
              itemId: id,
              stamp: stamp,
              carry: carry,
            ),
        ],
      ),
    );
  }
}
