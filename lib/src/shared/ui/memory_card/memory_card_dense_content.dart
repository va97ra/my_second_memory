import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../styled_text_span.dart';
import 'memory_item_presentation.dart';
import 'memory_card_attachment_icons.dart';
import 'memory_card_dense_title_row.dart';
import 'memory_card_labels.dart';
import 'memory_card_ruled_background.dart';

/// Содержимое плотной карточки ленты: заголовок и начало записи.
class MemoryCardDenseContent extends StatelessWidget {
  const MemoryCardDenseContent({super.key, required this.item});

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    final title = item.title.trim();
    final styled = StyledText.parse(item.body.trim());
    final body = styled.plain;
    // Заголовок, повторяющий начало записи, показывать дважды незачем.
    final showBody = body.isNotEmpty && _normalized(body) != _normalized(title);
    final hasAudio = item.voiceNotes.isNotEmpty;
    final hasAttachments = hasAudio || item.imagePaths.isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final typography = AppContentTypography.of(context);
    final titleStyle = typography.apply(
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: memoryTitleColor(colors, item),
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
    final status = memoryDoneLabel(context, item);

    return MemoryCardRuledBackground(
      lineHeight: typography.measuredLineHeight(titleStyle),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty || status != null)
              MemoryCardDenseTitleRow(
                itemId: item.id,
                title: styledMemoryTitle(item),
                titleStyle: titleStyle,
                status: status,
                imageCount: item.imagePaths.length,
                hasAudio: hasAudio,
                showAttachments: hasAttachments,
              ),
            if (title.isNotEmpty && showBody) ...[
              const SizedBox(height: 2),
              Text.rich(
                styledTextSpan(styled, bodyStyle),
                key: ValueKey('memory_card_body_${item.id}'),
                maxLines: bodyMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (title.isEmpty && body.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      styledTextSpan(styled, titleStyle),
                      key: ValueKey('memory_card_body_${item.id}'),
                      maxLines: bodyMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasAttachments) ...[
                    const SizedBox(width: 4),
                    MemoryCardAttachmentIcons(
                      imageCount: item.imagePaths.length,
                      hasAudio: hasAudio,
                      hasReminder: item.remindAt != null,
                    ),
                  ],
                ],
              ),
            if (item.type == MemoryType.payment &&
                item.amountMinor != null) ...[
              const SizedBox(height: 4),
              Text(
                memoryAmountLabel(item.amountMinor!),
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: memoryAccentColor(item),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
            if (item.type == MemoryType.birthday && item.birthYear != null) ...[
              const SizedBox(height: 4),
              Text(
                memoryAgeLabel(context, item),
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
    );
  }

  static String _normalized(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
