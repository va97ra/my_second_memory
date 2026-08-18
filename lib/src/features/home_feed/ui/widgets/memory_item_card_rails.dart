part of 'memory_item_card.dart';

class _TypeRail extends StatelessWidget {
  const _TypeRail({
    required this.item,
    required this.color,
    required this.showDate,
    required this.compact,
    required this.denseFeedLayout,
    super.key,
  });

  final MemoryItem item;
  final Color color;
  final bool showDate;
  final bool compact;
  final bool denseFeedLayout;

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
            vertical: denseFeedLayout
                ? 4
                : compact
                    ? 6
                    : 8,
          ),
          child: Column(
            children: [
              if (item.isUndated) const Spacer(),
              Icon(
                memoryTypeIcon(item.type),
                color: foreground,
                size: denseFeedLayout
                    ? 17
                    : compact
                        ? 19
                        : 21,
              ),
              SizedBox(height: denseFeedLayout ? 2 : (compact ? 3 : 5)),
              Text(
                item.isUndated
                    ? AppStrings.of(context).noteCard
                    : item.type.label(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontSize: denseFeedLayout
                          ? 7.8
                          : compact
                              ? 8.2
                              : 8.8,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
              ),
              const Spacer(),
              if (!item.isUndated && showDate)
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
              if (!item.isUndated)
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
      width: 40,
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
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: item.isDone
                      ? const Color(0xFF16A34A)
                      : colors.onSurfaceVariant,
                  backgroundColor: item.isDone
                      ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                      : Colors.transparent,
                  fixedSize: const Size.square(36),
                  minimumSize: const Size.square(36),
                  maximumSize: const Size.square(36),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (onToggleDone != null &&
                (onArchive != null || onRestore != null))
              const SizedBox(height: 4),
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
                  size: 19,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  backgroundColor:
                      const Color(0xFFB45309).withValues(alpha: 0.1),
                  fixedSize: const Size.square(36),
                  minimumSize: const Size.square(36),
                  maximumSize: const Size.square(36),
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
