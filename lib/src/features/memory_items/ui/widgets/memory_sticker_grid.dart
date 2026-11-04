import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'memory_sticker.dart';

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
    this.canCarry = false,
  });

  static const _gap = 8.0;
  static const _edge = 12.0;

  final List<String> itemIds;
  final int columns;
  final StickerStamp stamp;
  final String openQuery;
  final bool canCarry;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: _edge, vertical: 4),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: _gap,
          crossAxisSpacing: _gap,
        ),
        itemCount: itemIds.length,
        itemBuilder: (context, index) => MemorySticker(
          itemId: itemIds[index],
          stamp: stamp,
          openQuery: openQuery,
          canCarry: canCarry,
        ),
      ),
    );
  }
}
