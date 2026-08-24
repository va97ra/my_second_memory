import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Правая полоса плотной карточки: те же действия квадратными кнопками.
class MemoryCardDenseActionRail extends StatelessWidget {
  const MemoryCardDenseActionRail({
    super.key,
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
    final showArchive = onArchive != null || onRestore != null;

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
                style: _squareButtonStyle(
                  foreground: item.isDone
                      ? const Color(0xFF16A34A)
                      : colors.onSurfaceVariant,
                  background: item.isDone
                      ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
              ),
            if (onToggleDone != null && showArchive) const SizedBox(height: 4),
            if (showArchive)
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
                style: _squareButtonStyle(
                  foreground: const Color(0xFFB45309),
                  background: const Color(0xFFB45309).withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Обе кнопки одного размера: полоса узкая, и разнобой в ней виден сразу.
  ButtonStyle _squareButtonStyle({
    required Color foreground,
    required Color background,
  }) {
    return IconButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: background,
      fixedSize: const Size.square(36),
      minimumSize: const Size.square(36),
      maximumSize: const Size.square(36),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
