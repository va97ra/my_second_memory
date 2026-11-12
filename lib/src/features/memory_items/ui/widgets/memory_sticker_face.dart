import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import '../../../../shared/ui/memory_card/sticker_paper.dart';
import 'memory_sticker_content.dart';
import 'memory_sticker_done_box.dart';
import 'memory_sticker_strip.dart';

/// Сама карточка: бумага, полоса вида и даты, текст и квадратик выполнения.
class MemoryStickerFace extends StatelessWidget {
  const MemoryStickerFace({
    super.key,
    required this.item,
    required this.stamp,
    this.lifted = false,
    this.onOpen,
    this.onToggleDone,
  });

  final MemoryItem item;
  final StickerStamp stamp;
  final bool lifted;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final content = MemoryStickerContent(item: item);
    return PressPulse(
      child: StickerPaper(
        accent: memoryAccentColor(item),
        lifted: lifted,
        strip: MemoryStickerStrip(
          key: ValueKey('memory_sticker_strip_${item.id}'),
          item: item,
          stamp: stamp,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (onOpen == null)
              content
            else
              NotebookPressable(
                onTap: onOpen,
                borderRadius: BorderRadius.zero,
                pulse: false,
                child: content,
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: MemoryStickerDoneBox(
                key: ValueKey('memory_sticker_done_${item.id}'),
                isDone: item.isDone,
                onToggle: onToggleDone ?? () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
