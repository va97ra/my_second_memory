import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../memory_items/domain/memory_item.dart';
import '../../../memory_items/domain/memory_type.dart';
import '../../../voice_notes/ui/widgets/voice_note_player.dart';
import 'memory_image_preview.dart';

class MemoryItemCard extends StatelessWidget {
  const MemoryItemCard({
    required this.item,
    required this.onOpen,
    required this.onToggleDone,
    super.key,
  });

  final MemoryItem item;
  final VoidCallback onOpen;
  final VoidCallback onToggleDone;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat.yMMMd(locale).format(item.memoryDate);
    const doneColor = Color(0xFF16A34A);
    final isDone = item.isDone;
    final typeColor = _typeColor(item.type);
    final cardColor =
        isDone ? const Color(0xFFEAF8EF) : typeColor.withValues(alpha: 0.075);
    final borderColor =
        isDone ? const Color(0xFF86EFAC) : typeColor.withValues(alpha: 0.28);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: (isDone ? doneColor : typeColor)
                      .withValues(alpha: isDone ? 0.08 : 0.075),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: (isDone ? doneColor : typeColor)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isDone ? doneColor : typeColor)
                                .withValues(alpha: 0.28),
                          ),
                        ),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            isDone ? Icons.check_circle : _iconFor(item.type),
                            size: 19,
                            color: isDone ? doneColor : typeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.18,
                                    color:
                                        isDone ? const Color(0xFF14532D) : null,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _MetaPill(
                                  text: item.type.label(locale),
                                  color: isDone ? doneColor : typeColor,
                                ),
                                _MetaPill(text: date),
                                if (isDone)
                                  _MetaPill(
                                    text: AppStrings.of(context).completed,
                                    color: doneColor,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isDone
                            ? AppStrings.of(context).markActive
                            : AppStrings.of(context).markDone,
                        onPressed: onToggleDone,
                        icon: Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          size: 22,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor:
                              isDone ? Colors.white : const Color(0xFF16A34A),
                          backgroundColor: isDone
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEAF8EF),
                          minimumSize: const Size(36, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            color: isDone
                                ? const Color(0xFF166534)
                                : const Color(0xFF334155),
                          ),
                    ),
                  ],
                  if (item.audioPath != null) ...[
                    const SizedBox(height: 12),
                    VoiceNotePlayer(path: item.audioPath!),
                  ],
                  if (item.imagePaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ImageStrip(paths: item.imagePaths),
                  ],
                ],
              ),
            ),
          ),
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

  Color _typeColor(MemoryType type) {
    return switch (type) {
      MemoryType.task => const Color(0xFF16A34A),
      MemoryType.note => const Color(0xFF2563EB),
      MemoryType.voiceNote => const Color(0xFFDB2777),
      MemoryType.event => const Color(0xFF7C3AED),
      MemoryType.person => const Color(0xFF0891B2),
      MemoryType.habit => const Color(0xFF059669),
      MemoryType.goal => const Color(0xFFEA580C),
      MemoryType.project => const Color(0xFF4F46E5),
      MemoryType.purchase => const Color(0xFFCA8A04),
      MemoryType.document => const Color(0xFF475569),
      MemoryType.place => const Color(0xFFDC2626),
    };
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.text,
    this.color = const Color(0xFF64748B),
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = paths[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 128,
              height: 92,
              child: MemoryImagePreview(path: path),
            ),
          );
        },
      ),
    );
  }
}
