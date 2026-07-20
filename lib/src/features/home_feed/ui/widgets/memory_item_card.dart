import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../memory_items/domain/memory_item.dart';
import '../../../memory_items/domain/memory_type.dart';
import '../../../memory_items/ui/widgets/memory_item_presentation.dart';
import '../../../voice_notes/ui/widgets/voice_note_player.dart';
import 'memory_image_preview.dart';
import 'memory_image_viewer.dart';

class MemoryItemCard extends StatelessWidget {
  const MemoryItemCard({
    required this.item,
    required this.onOpen,
    this.onToggleDone,
    this.onArchive,
    this.onRestore,
    this.showDate = true,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    super.key,
  });

  final MemoryItem item;
  final VoidCallback onOpen;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final bool showDate;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final typeColor = memoryTypeColor(item.type);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = item.isDone
        ? Color.alphaBlend(
            const Color(0xFF16A34A).withValues(alpha: isDark ? 0.14 : 0.08),
            colors.surface,
          )
        : colors.surface;
    final borderColor = item.isDone
        ? const Color(0xFF86EFAC)
        : typeColor.withValues(alpha: 0.34);

    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          key: ValueKey('memory_card_${item.id}'),
          height: 124,
          child: Ink(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: typeColor.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: onOpen,
                    child: _TypeRail(
                      key: ValueKey('memory_card_type_${item.id}'),
                      item: item,
                      color: typeColor,
                      showDate: showDate,
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: onOpen,
                      child: _CardContent(
                        key: ValueKey('memory_card_content_${item.id}'),
                        item: item,
                      ),
                    ),
                  ),
                  _ActionRail(
                    key: ValueKey('memory_card_actions_${item.id}'),
                    item: item,
                    onToggleDone: onToggleDone,
                    onArchive: onArchive,
                    onRestore: onRestore,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeRail extends StatelessWidget {
  const _TypeRail({
    required this.item,
    required this.color,
    required this.showDate,
    super.key,
  });

  final MemoryItem item;
  final Color color;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final time = item.timeMinutes == null
        ? DateFormat.Hm(locale).format(item.createdAt)
        : formatMemoryTime(item.timeMinutes!);

    return ColoredBox(
      color: color,
      child: SizedBox(
        width: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Column(
            children: [
              Icon(memoryTypeIcon(item.type), color: Colors.white, size: 20),
              const SizedBox(height: 5),
              Text(
                item.type.label(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
              ),
              const Spacer(),
              if (showDate)
                Text(
                  DateFormat.MMMd(locale).format(item.memoryDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              Text(
                time,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.item,
    super.key,
  });

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    final text = item.title.trim().isNotEmpty ? item.title.trim() : item.body;
    final hasAudio = item.audioPath != null;
    final hasImage = item.imagePaths.isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
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
                    maxLines: hasAudio ? 2 : 5,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: item.isDone
                              ? (isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF14532D))
                              : colors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                  ),
                if (item.type == MemoryType.payment &&
                    item.amountMinor != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormat.decimalPattern('ru').format(item.amountMinor! ~/ 100)} ₽',
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
                    Localizations.localeOf(context).languageCode == 'ru'
                        ? '${item.memoryDate.year - item.birthYear!} лет'
                        : '${item.memoryDate.year - item.birthYear!} years',
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
                  ),
                ],
              ],
            ),
          ),
          if (hasImage) ...[
            const SizedBox(width: 8),
            _ImageThumbnail(paths: item.imagePaths),
          ],
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final path = paths.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('feed_image_$path'),
          onTap: () => openMemoryImageViewer(context, path),
          child: SizedBox(
            width: 58,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MemoryImagePreview(path: path, cacheWidth: 720),
                if (paths.length > 1)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        child: Text(
                          '+${paths.length - 1}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.item,
    this.onToggleDone,
    this.onArchive,
    this.onRestore,
    super.key,
  });

  final MemoryItem item;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final status = item.isArchived
        ? strings.archive
        : item.isDone
            ? item.type == MemoryType.payment
                ? (Localizations.localeOf(context).languageCode == 'ru'
                    ? 'Оплачено'
                    : 'Paid')
                : strings.completed
            : null;

    return SizedBox(
      width: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            if (onToggleDone != null)
              IconButton(
                key: ValueKey('memory_card_done_${item.id}'),
                tooltip: item.isDone ? strings.markActive : strings.markDone,
                onPressed: onToggleDone,
                icon: Icon(
                  item.isDone ? Icons.check_circle : Icons.check_circle_outline,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: item.isDone
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF94A3B8),
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (onArchive != null || onRestore != null)
              IconButton(
                key: ValueKey('memory_card_archive_${item.id}'),
                tooltip: onRestore != null
                    ? strings.restoreToFeed
                    : strings.archiveRecord,
                onPressed: onRestore ?? onArchive,
                icon: Icon(
                  onRestore != null
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 22,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            const Spacer(),
            if (status != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: item.isArchived
                            ? const Color(0xFF92400E)
                            : const Color(0xFF15803D),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
