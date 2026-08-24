import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'memory_item_presentation.dart';
import '../media/voice_note_player.dart';
import 'memory_card_image_thumbnail.dart';
import 'memory_card_labels.dart';
import 'memory_card_ruled_background.dart';

/// Содержимое обычной карточки: текст записи, её числа и вложения.
class MemoryCardContent extends StatelessWidget {
  const MemoryCardContent({
    super.key,
    required this.item,
    required this.compact,
  });

  final MemoryItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = item.title.trim().isNotEmpty ? item.title.trim() : item.body;
    final hasAudio = item.audioPath != null;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typography = AppContentTypography.of(context);
    final contentStyle = typography.apply(
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: item.isDone
                ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D))
                : colors.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
      manropeWeight: FontWeight.w700,
    );

    return MemoryCardRuledBackground(
      lineHeight: typography.measuredLineHeight(contentStyle),
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(8, 6, 6, 6)
            : const EdgeInsets.fromLTRB(10, 9, 8, 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text.isNotEmpty)
                    Text(
                      text,
                      maxLines:
                          hasAudio ? (compact ? 1 : 2) : (compact ? 4 : 5),
                      overflow: TextOverflow.ellipsis,
                      style: contentStyle,
                    ),
                  if (item.type == MemoryType.payment &&
                      item.amountMinor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      memoryAmountLabel(item.amountMinor!),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: memoryTypeColor(item.type),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                  if (item.type == MemoryType.birthday &&
                      item.birthYear != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      memoryAgeLabel(context, item),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                  if (hasAudio) ...[
                    const Spacer(),
                    VoiceNotePlayer(
                      path: item.audioPath!,
                      recordedAt: item.memoryDate,
                      durationSeconds: item.audioDurationSeconds,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),
            if (item.imagePaths.isNotEmpty) ...[
              SizedBox(width: compact ? 6 : 8),
              MemoryCardImageThumbnail(
                paths: item.imagePaths,
                compact: compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
