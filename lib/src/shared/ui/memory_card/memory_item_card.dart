import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'memory_item_presentation.dart';
import 'memory_card_action_rail.dart';
import 'memory_card_content.dart';
import 'memory_card_paper.dart';
import 'memory_card_type_rail.dart';

/// Запись в виде отдельного листка: полоса вида, содержимое и действия.
class MemoryItemCard extends StatelessWidget {
  const MemoryItemCard({
    super.key,
    required this.item,
    required this.onOpen,
    this.onToggleDone,
    this.onArchive,
    this.onRestore,
    this.showDate = true,
    this.compact = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
  });

  final MemoryItem item;
  final VoidCallback onOpen;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final bool showDate;
  final bool compact;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    // Выполненная запись сереет целиком — полоса вида, кромка и заголовок,
    // — а бумага остаётся бумагой: сделанное дело листок не перекрашивает.
    final accent = memoryAccentColor(item);
    return MemoryCardPaper(
      cardKey: ValueKey('memory_card_${item.id}'),
      variantKey: item.id,
      borderColor: accent.withValues(alpha: 0.34),
      height: _height,
      margin: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Бумага не отзывается волной. Нажатие давит на весь лист, а полоса
          // действий остаётся своей целью.
          Expanded(
            child: NotebookPressable(
              onTap: onOpen,
              borderRadius: BorderRadius.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MemoryCardTypeRail(
                    key: ValueKey('memory_card_type_${item.id}'),
                    item: item,
                    color: accent,
                    showDate: showDate,
                    compact: compact,
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey('memory_card_content_${item.id}'),
                      child: MemoryCardContent(item: item, compact: compact),
                    ),
                  ),
                ],
              ),
            ),
          ),
          MemoryCardActionRail(
            key: ValueKey('memory_card_actions_${item.id}'),
            item: item,
            compact: compact,
            onToggleDone: onToggleDone,
            onArchive: onArchive,
            onRestore: onRestore,
          ),
        ],
      ),
    );
  }

  double get _height => compact ? 108 : 118;
}
