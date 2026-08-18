part of 'memory_item_card.dart';

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
    final hasAttachments = hasAudio || hasImage;
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
    final bodyMaxLines = title.isEmpty ? 3 : 2;
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
                      if (hasAttachments) ...[
                        const SizedBox(width: 4),
                        _DenseAttachmentIndicators(
                          imageCount: item.imagePaths.length,
                          hasAudio: hasAudio,
                        ),
                      ],
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          body,
                          key: ValueKey('memory_card_body_${item.id}'),
                          maxLines: bodyMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                      if (hasAttachments) ...[
                        const SizedBox(width: 4),
                        _DenseAttachmentIndicators(
                          imageCount: item.imagePaths.length,
                          hasAudio: hasAudio,
                        ),
                      ],
                    ],
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
              ],
            ),
          ),
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

class _DenseAttachmentIndicators extends StatelessWidget {
  const _DenseAttachmentIndicators({
    required this.imageCount,
    required this.hasAudio,
  });

  final int imageCount;
  final bool hasAudio;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageCount > 0) ...[
          Icon(Icons.image_rounded, size: 16, color: color),
          if (imageCount > 1)
            Text(
              '$imageCount',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
            ),
        ],
        if (imageCount > 0 && hasAudio) const SizedBox(width: 3),
        if (hasAudio) Icon(Icons.mic_rounded, size: 16, color: color),
      ],
    );
  }
}

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
