import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_attachment_icons.dart';
import '../../../../shared/ui/memory_card/memory_fitted_text.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'memory_sticker_done_box.dart';

/// Текст записи на столько строк, сколько влезает, и ряд её вложений.
class MemoryStickerContent extends StatelessWidget {
  const MemoryStickerContent({super.key, required this.item});

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = AppContentTypography.of(context).apply(
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: memoryTitleColor(colors, item),
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
      manropeWeight: FontWeight.w600,
    );
    final hasAudio = item.voiceNotes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: MemoryFittedText(item: item, style: style)),
          // Ряд вложений и место под квадратик выполнения в углу.
          SizedBox(
            height: MemoryStickerDoneBox.boxSize,
            child: hasAudio || item.imagePaths.isNotEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: MemoryCardAttachmentIcons(
                      imageCount: item.imagePaths.length,
                      hasAudio: hasAudio,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
