import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_attachment_icons.dart';
import '../../../../shared/ui/memory_card/memory_card_image_thumbnail.dart';
import '../../../../shared/ui/memory_card/memory_fitted_text.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'day_timeline_geometry.dart';

/// Содержимое записи на шкале. Цветная полоса здесь сбоку, а не сверху, как у
/// квадратных карточек: высота таблички — это длительность, и у записи на четверть
/// часа верхняя полоса закрыла бы весь текст.
class DayTimelineCardBody extends StatelessWidget {
  const DayTimelineCardBody({super.key, required this.block});

  static const _stripWidth = 6.0;

  final DayTimelineBlock block;

  @override
  Widget build(BuildContext context) {
    final short = block.height < dayTimelineHourHeight / 2;
    final colors = Theme.of(context).colorScheme;
    final item = block.item;
    // Миниатюра просит высоты: на четверти часа ей не поместиться, там
    // о фотографии говорит значок.
    final tall = block.height >= 2 * dayTimelineHourHeight / 3;
    final hasImages = item.imagePaths.isNotEmpty;
    final style = AppContentTypography.of(context).apply(
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: memoryTitleColor(colors, item),
            // На четверти часа подпись живёт одной мелкой строкой.
            fontSize: short ? 11 : null,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
      manropeWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: memoryAccentColor(item),
          child: const SizedBox(width: _stripWidth),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(7, short ? 1 : 5, 7, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tall && hasImages) ...[
                  SizedBox(
                    height: 44,
                    child: MemoryCardImageThumbnail(
                      paths: item.imagePaths,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(child: MemoryFittedText(item: item, style: style)),
                if (!(tall && hasImages) ||
                    item.voiceNotes.isNotEmpty ||
                    item.remindAt != null) ...[
                  const SizedBox(width: 4),
                  MemoryCardAttachmentIcons(
                    imageCount: tall && hasImages ? 0 : item.imagePaths.length,
                    hasAudio: item.voiceNotes.isNotEmpty,
                    hasReminder: item.remindAt != null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
