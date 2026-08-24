import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'memory_card_labels.dart';

/// Правая полоса карточки: завершить, архивировать и текущее состояние.
class MemoryCardActionRail extends StatelessWidget {
  const MemoryCardActionRail({
    super.key,
    required this.item,
    required this.compact,
    this.onToggleDone,
    this.onArchive,
    this.onRestore,
  });

  final MemoryItem item;
  final bool compact;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final status =
        item.isArchived ? strings.archive : memoryDoneLabel(context, item);

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
                style: notebookIconButtonStyle(
                  foregroundColor: item.isDone
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF94A3B8),
                  shrinkTapTarget: true,
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
                style: notebookIconButtonStyle(
                  foregroundColor: const Color(0xFFB45309),
                  shrinkTapTarget: true,
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
