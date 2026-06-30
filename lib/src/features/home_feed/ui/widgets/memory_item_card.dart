import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../memory_items/domain/memory_item.dart';
import '../../../memory_items/domain/memory_type.dart';
import '../../../voice_notes/ui/widgets/voice_note_player.dart';

class MemoryItemCard extends StatelessWidget {
  const MemoryItemCard({
    required this.item,
    this.onArchive,
    super.key,
  });

  final MemoryItem item;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat.yMMMd(locale).format(item.memoryDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(item.type), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.type.label(locale)} · $date',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onArchive != null)
                  IconButton(
                    tooltip: 'Archive',
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined),
                  ),
              ],
            ),
            if (item.body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(item.body),
            ],
            if (item.audioPath != null) ...[
              const SizedBox(height: 12),
              VoiceNotePlayer(path: item.audioPath!),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(MemoryType type) {
    return switch (type) {
      MemoryType.task => Icons.check_circle_outline,
      MemoryType.note => Icons.notes,
      MemoryType.voiceNote => Icons.mic_none,
      MemoryType.event => Icons.event,
      MemoryType.person => Icons.person_outline,
      MemoryType.habit => Icons.repeat,
      MemoryType.goal => Icons.flag_outlined,
      MemoryType.project => Icons.folder_outlined,
      MemoryType.purchase => Icons.shopping_bag_outlined,
      MemoryType.document => Icons.description_outlined,
      MemoryType.place => Icons.place_outlined,
    };
  }
}
