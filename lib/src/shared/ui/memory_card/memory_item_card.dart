import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'memory_item_presentation.dart';
import 'memory_card_action_rail.dart';
import 'memory_card_content.dart';
import 'memory_card_dense_action_rail.dart';
import 'memory_card_dense_content.dart';
import 'memory_card_labels.dart';
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
    this.denseFeedLayout = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MemoryCardPaper(
      cardKey: ValueKey('memory_card_${item.id}'),
      variantKey: item.id,
      cardColor: item.isDone
          ? Color.alphaBlend(
              const Color(0xFF16A34A).withValues(alpha: isDark ? 0.14 : 0.08),
              colors.surface,
            )
          : colors.surface,
      borderColor: item.isDone
          ? const Color(0xFF86EFAC)
          : typeColor.withValues(alpha: 0.34),
      height: _height(context),
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
                    color: typeColor,
                    showDate: showDate,
                    compact: compact,
                    denseFeedLayout: denseFeedLayout,
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey('memory_card_content_${item.id}'),
                      child: denseFeedLayout
                          ? MemoryCardDenseContent(item: item)
                          : MemoryCardContent(item: item, compact: compact),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (denseFeedLayout)
            MemoryCardDenseActionRail(
              key: ValueKey('memory_card_actions_${item.id}'),
              item: item,
              onToggleDone: onToggleDone,
              onArchive: onArchive,
              onRestore: onRestore,
            )
          else
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

  double _height(BuildContext context) {
    if (denseFeedLayout) {
      return denseFeedCardHeight(context) + (showDate ? 8 : 0);
    }
    return compact ? 108 : 118;
  }
}
