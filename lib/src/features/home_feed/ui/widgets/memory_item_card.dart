import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_content_font.dart';
import '../../../../core/theme/app_surface_palette.dart';
import '../../../../core/theme/app_surface_textures.dart';
import '../../../../core/theme/notebook/notebook_assets.dart';
import '../../../../core/theme/notebook/notebook_background.dart';
import '../../../../core/theme/notebook/notebook_leather_surface.dart';
import '../../../../core/theme/notebook/notebook_visuals.dart';
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
    this.compact = false,
    this.denseFeedLayout = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    super.key,
  });

  final MemoryItem item;
  final VoidCallback onOpen;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final bool showDate;
  final bool compact;
  final bool denseFeedLayout;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final typeColor = memoryTypeColor(item.type);
    final colors = Theme.of(context).colorScheme;
    final textures = AppSurfaceTextures.maybeOf(context);
    final notebook = NotebookVisuals.maybeOf(context);
    final palette = AppSurfacePalette.of(context);
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
    final cardShadowColor = notebook != null
        ? const Color(0xFF3B1D0E).withValues(alpha: 0.5)
        : isDark
            ? Colors.black.withValues(alpha: 0.68)
            : const Color(0xFF536575).withValues(alpha: 0.34);

    return Padding(
      padding: margin,
      child: Material(
        color: cardColor,
        elevation: 6,
        shadowColor: cardShadowColor,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          key: ValueKey('memory_card_${item.id}'),
          height: denseFeedLayout
              ? _denseFeedCardHeight(context)
              : compact
                  ? 108
                  : 118,
          child: Ink(
            decoration: BoxDecoration(
              color: notebook == null ? null : cardColor,
              gradient: notebook == null
                  ? palette.surfaceGradient(base: cardColor)
                  : null,
              image: notebook != null
                  ? const DecorationImage(
                      image: AssetImage(NotebookAssets.paper),
                      fit: BoxFit.cover,
                      opacity: 0.5,
                    )
                  : textures == null
                      ? null
                      : DecorationImage(
                          image: AssetImage(textures.surfaceAsset),
                          fit: BoxFit.cover,
                          opacity: textures.surfaceOpacity,
                          filterQuality: FilterQuality.low,
                        ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: onOpen,
                        child: _TypeRail(
                          key: ValueKey('memory_card_type_${item.id}'),
                          item: item,
                          color: typeColor,
                          showDate: showDate,
                          compact: compact,
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: onOpen,
                          child: _CardContent(
                            key: ValueKey('memory_card_content_${item.id}'),
                            item: item,
                            compact: compact,
                            denseFeedLayout: denseFeedLayout,
                          ),
                        ),
                      ),
                      _ActionRail(
                        key: ValueKey('memory_card_actions_${item.id}'),
                        item: item,
                        compact: compact,
                        denseFeedLayout: denseFeedLayout,
                        onToggleDone: onToggleDone,
                        onArchive: onArchive,
                        onRestore: onRestore,
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                    ),
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

double _denseFeedCardHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  if (scale <= 1.3) {
    return 96 + ((scale - 1).clamp(0.0, 0.3) * 24);
  }
  final largeTextProgress = ((scale - 1.3) / 0.7).clamp(0.0, 1.0);
  return 103.2 + largeTextProgress * 72.8;
}

class _TypeRail extends StatelessWidget {
  const _TypeRail({
    required this.item,
    required this.color,
    required this.showDate,
    required this.compact,
    super.key,
  });

  final MemoryItem item;
  final Color color;
  final bool showDate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final foreground = NotebookVisuals.maybeOf(context) == null
        ? Colors.white
        : notebookLeatherForeground(color);
    final time = item.timeMinutes == null
        ? DateFormat.Hm(locale).format(item.createdAt)
        : formatMemoryTime(item.timeMinutes!);

    return NotebookLeatherSurface(
      color: color,
      child: SizedBox(
        width: compact ? 50 : 54,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 3,
            vertical: compact ? 6 : 8,
          ),
          child: Column(
            children: [
              Icon(
                memoryTypeIcon(item.type),
                color: foreground,
                size: compact ? 19 : 21,
              ),
              SizedBox(height: compact ? 3 : 5),
              Text(
                item.type.label(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontSize: compact ? 8.2 : 8.8,
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
                        color: foreground.withValues(alpha: 0.88),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              Text(
                time,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontSize: compact ? 10 : 10.5,
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
    required this.compact,
    required this.denseFeedLayout,
    super.key,
  });

  final MemoryItem item;
  final bool compact;
  final bool denseFeedLayout;

  @override
  Widget build(BuildContext context) {
    if (denseFeedLayout) {
      return _DenseFeedCardContent(item: item);
    }
    final text = item.title.trim().isNotEmpty ? item.title.trim() : item.body;
    final hasAudio = item.audioPath != null;
    final hasImage = item.imagePaths.isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
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
    final lineHeight = typography.measuredLineHeight(contentStyle);

    final content = Padding(
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
                    maxLines: hasAudio ? (compact ? 1 : 2) : (compact ? 4 : 5),
                    overflow: TextOverflow.ellipsis,
                    style: contentStyle,
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
                    compact: true,
                  ),
                ],
              ],
            ),
          ),
          if (hasImage) ...[
            SizedBox(width: compact ? 6 : 8),
            _ImageThumbnail(
              paths: item.imagePaths,
              compact: compact,
              denseFeedLayout: false,
            ),
          ],
        ],
      ),
    );
    final lineColor = notebook?.line ?? textures?.lineColor;
    if (lineColor == null) return content;
    return CustomPaint(
      painter: NotebookPaperLinesPainter(
        color: lineColor,
        top: 6 + lineHeight,
        lineHeight: lineHeight,
      ),
      child: content,
    );
  }
}

class _DenseFeedCardContent extends StatelessWidget {
  const _DenseFeedCardContent({required this.item});

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    final title = item.title.trim();
    final body = item.body.trim();
    final showBody = body.isNotEmpty &&
        _normalizedCardText(body) != _normalizedCardText(title);
    final hasAudio = item.audioPath != null;
    final hasImage = item.imagePaths.isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
    final typography = AppContentTypography.of(context);
    final titleStyle = typography.apply(
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: item.isDone
                ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D))
                : colors.onSurface,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
      manropeWeight: FontWeight.w800,
    );
    final bodyStyle = typography.apply(
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
      manropeWeight: FontWeight.w600,
    );
    final bodyMaxLines = hasAudio
        ? 1
        : title.isEmpty
            ? 3
            : 2;
    final status = item.isDone
        ? item.type == MemoryType.payment
            ? (Localizations.localeOf(context).languageCode == 'ru'
                ? 'Оплачено'
                : 'Paid')
            : AppStrings.of(context).completed
        : null;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty || status != null)
                  Row(
                    children: [
                      if (title.isNotEmpty)
                        Expanded(
                          child: Text(
                            title,
                            key: ValueKey('memory_card_title_${item.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        )
                      else
                        const Spacer(),
                      if (status != null) ...[
                        const SizedBox(width: 4),
                        DecoratedBox(
                          key: ValueKey('memory_card_status_${item.id}'),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.52),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            child: Text(
                              status,
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isDark
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFF14532D),
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                if (title.isNotEmpty && showBody) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    key: ValueKey('memory_card_body_${item.id}'),
                    maxLines: bodyMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle,
                  ),
                ] else if (title.isEmpty && body.isNotEmpty)
                  Text(
                    body,
                    key: ValueKey('memory_card_body_${item.id}'),
                    maxLines: bodyMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                if (item.type == MemoryType.payment &&
                    item.amountMinor != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormat.decimalPattern('ru').format(item.amountMinor! ~/ 100)} ₽',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
          if (hasImage) ...[
            const SizedBox(width: 8),
            _ImageThumbnail(
              paths: item.imagePaths,
              compact: true,
              denseFeedLayout: true,
            ),
          ],
        ],
      ),
    );
    final lineColor = notebook?.line ?? textures?.lineColor;
    if (lineColor == null) return content;
    final lineHeight = typography.measuredLineHeight(titleStyle);
    return CustomPaint(
      painter: NotebookPaperLinesPainter(
        color: lineColor,
        top: 6 + lineHeight,
        lineHeight: lineHeight,
      ),
      child: content,
    );
  }
}

String _normalizedCardText(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.paths,
    required this.compact,
    required this.denseFeedLayout,
  });

  final List<String> paths;
  final bool compact;
  final bool denseFeedLayout;

  @override
  Widget build(BuildContext context) {
    final path = paths.first;
    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('feed_image_$path'),
          onTap: () => openMemoryImageViewer(context, path),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MemoryImagePreview(
                path: path,
                fit: BoxFit.contain,
                cacheWidth: 720,
              ),
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    );
    final width = compact ? 48.0 : 54.0;
    if (!denseFeedLayout) return SizedBox(width: width, child: thumbnail);
    return Align(
      alignment: Alignment.center,
      child: SizedBox(width: width, height: 64, child: thumbnail),
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.item,
    required this.compact,
    required this.denseFeedLayout,
    this.onToggleDone,
    this.onArchive,
    this.onRestore,
    super.key,
  });

  final MemoryItem item;
  final bool compact;
  final bool denseFeedLayout;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (denseFeedLayout) {
      return _DenseFeedActionRail(
        item: item,
        onToggleDone: onToggleDone,
        onArchive: onArchive,
        onRestore: onRestore,
      );
    }
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
      width: compact ? 48 : 54,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 5 : 6),
        child: Column(
          children: [
            if (onToggleDone != null)
              IconButton(
                key: ValueKey('memory_card_done_${item.id}'),
                tooltip: item.isDone ? strings.markActive : strings.markDone,
                onPressed: onToggleDone,
                icon: Icon(
                  item.isDone
                      ? Icons.check_circle_rounded
                      : Icons.task_alt_rounded,
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
                      ? Icons.unarchive_rounded
                      : Icons.archive_rounded,
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    status,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: item.isArchived
                              ? const Color(0xFF92400E)
                              : const Color(0xFF15803D),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DenseFeedActionRail extends StatelessWidget {
  const _DenseFeedActionRail({
    required this.item,
    this.onToggleDone,
    this.onArchive,
    this.onRestore,
  });

  final MemoryItem item;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.28),
          border: Border(
            left: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.62),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onToggleDone != null)
              IconButton(
                key: ValueKey('memory_card_done_${item.id}'),
                tooltip: item.isDone ? strings.markActive : strings.markDone,
                onPressed: onToggleDone,
                icon: Icon(
                  item.isDone
                      ? Icons.check_circle_rounded
                      : Icons.task_alt_rounded,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: item.isDone
                      ? const Color(0xFF16A34A)
                      : colors.onSurfaceVariant,
                  backgroundColor: item.isDone
                      ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                      : Colors.transparent,
                  fixedSize: const Size.square(48),
                  minimumSize: const Size.square(48),
                  maximumSize: const Size.square(48),
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
                      ? Icons.unarchive_rounded
                      : Icons.archive_rounded,
                  size: 22,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  backgroundColor:
                      const Color(0xFFB45309).withValues(alpha: 0.1),
                  fixedSize: const Size.square(48),
                  minimumSize: const Size.square(48),
                  maximumSize: const Size.square(48),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
