import 'package:flutter/material.dart';
import 'package:ez_design/ez_design.dart';
import '../../../../shared/ui/memory_card/memory_card_attachment_icons.dart';
import '../../../../shared/ui/memory_card/memory_card_image_thumbnail.dart';
import '../../../../shared/ui/memory_card/memory_card_ruled_background.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'day_timeline_geometry.dart';

class DayTimelineCardBody extends StatelessWidget {
  const DayTimelineCardBody({super.key, required this.block});
  final DayTimelineBlock block;
  @override
  Widget build(BuildContext context) {
    final short = block.height < dayTimelineHourHeight / 2;
    final colors = Theme.of(context).colorScheme;
    final item = block.item;
    final notebook = NotebookVisuals.maybeOf(context);
    // Рваный край откусывает часть корешка, поэтому ширину ему добавляют.
    final tearInset = notebook == null ? 0.0 : TornPaperShapeBorder.tearDepth;
    // Миниатюра просит высоты: на четверти часа ей не поместиться, там
    // о фотографии говорит значок.
    final tall = block.height >= 2 * dayTimelineHourHeight / 3;
    final hasImages = item.imagePaths.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NotebookLeatherSurface(
          color: memoryAccentColor(item),
          child: SizedBox(width: 10 + tearInset),
        ),
        Expanded(
          child: MemoryCardRuledBackground(
            lineHeight: short ? 12 : 16,
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
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: short ? 1 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: memoryTitleColor(colors, item),
                        // На четверти часа подпись живёт одной мелкой строкой.
                        fontSize: short ? 11 : 13,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (!(tall && hasImages) ||
                      item.voiceNotes.isNotEmpty ||
                      item.remindAt != null) ...[
                    const SizedBox(width: 4),
                    MemoryCardAttachmentIcons(
                      imageCount:
                          tall && hasImages ? 0 : item.imagePaths.length,
                      hasAudio: item.voiceNotes.isNotEmpty,
                      hasReminder: item.remindAt != null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
