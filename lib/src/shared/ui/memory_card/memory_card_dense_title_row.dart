import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../styled_text_span.dart';
import 'memory_card_attachment_icons.dart';
import 'memory_card_status_chip.dart';

/// Верхняя строка плотной карточки: заголовок, значки вложений и отметка
/// «выполнено».
class MemoryCardDenseTitleRow extends StatelessWidget {
  const MemoryCardDenseTitleRow({
    super.key,
    required this.itemId,
    required this.title,
    required this.titleStyle,
    required this.status,
    required this.imageCount,
    required this.hasAudio,
    required this.showAttachments,
  });

  final String itemId;
  /// Название с оформлением текста записи.
  final StyledText title;
  final TextStyle? titleStyle;
  final String? status;
  final int imageCount;
  final bool hasAudio;
  final bool showAttachments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (title.plain.isNotEmpty)
          Expanded(
            child: Text.rich(
              styledTextSpan(title, titleStyle ?? const TextStyle()),
              key: ValueKey('memory_card_title_$itemId'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          const Spacer(),
        if (showAttachments) ...[
          const SizedBox(width: 4),
          MemoryCardAttachmentIcons(
            imageCount: imageCount,
            hasAudio: hasAudio,
          ),
        ],
        if (status != null) ...[
          const SizedBox(width: 4),
          MemoryCardStatusChip(
            key: ValueKey('memory_card_status_$itemId'),
            label: status!,
          ),
        ],
      ],
    );
  }
}
