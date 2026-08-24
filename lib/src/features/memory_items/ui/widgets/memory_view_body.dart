import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/media/voice_note_player.dart';
import '../../../../shared/ui/memory_card/memory_card_labels.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import 'readonly_image_grid.dart';

/// Содержимое безопасного просмотра: фотографии, голос, текст и числа записи.
class MemoryViewBody extends StatelessWidget {
  const MemoryViewBody({super.key, required this.item});

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasImages = item.imagePaths.isNotEmpty;
    final hasAudio = item.audioPath != null;
    final text = item.body.trim().isNotEmpty ? item.body.trim() : item.title;

    return SingleChildScrollView(
      key: const ValueKey('memory_readonly_content'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImages) ReadonlyImageGrid(paths: item.imagePaths),
          if (hasAudio) ...[
            if (hasImages) const SizedBox(height: 12),
            VoiceNotePlayer(
              path: item.audioPath!,
              recordedAt: item.memoryDate,
              durationSeconds: item.audioDurationSeconds,
            ),
          ],
          if (text.isNotEmpty) ...[
            if (hasImages || hasAudio) const SizedBox(height: 12),
            Text(
              text,
              style: AppContentTypography.of(context).apply(
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                      height: 1.36,
                      fontWeight: FontWeight.w600,
                    ),
                manropeWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item.type == MemoryType.payment && item.amountMinor != null) ...[
            const SizedBox(height: 10),
            Text(
              memoryAmountLabel(item.amountMinor!),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: memoryTypeColor(item.type),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
          if (item.type == MemoryType.birthday && item.birthYear != null) ...[
            const SizedBox(height: 10),
            Text(
              memoryAgeLabel(context, item),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
