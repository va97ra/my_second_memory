import 'dart:math' as math;

import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../styled_text_span.dart';

/// Текст записи на столько строк, сколько есть места: в маленькой карточке
/// начало с многоточием, в большой — весь.
class MemoryFittedText extends StatelessWidget {
  const MemoryFittedText({super.key, required this.item, required this.style});

  final MemoryItem item;

  /// Готовый стиль: шрифт содержимого в него уже подставлен.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final typography = AppContentTypography.of(context);
    final body = StyledText.parse(item.body.trim());
    final title = item.title.trim();
    // Название — обычно начало самого текста, и показывать его дважды незачем.
    // Но бывает и своё: у дня рождения это имя, а текста может не быть вовсе.
    final showsTitle = title.isNotEmpty &&
        !body.plain.startsWith(title.replaceFirst(RegExp(r'\.\.\.$'), ''));

    return LayoutBuilder(
      // Сколько строк влезает, столько и показываем: многоточие лучше,
      // чем буквы, обрезанные по краю карточки.
      builder: (context, constraints) {
        final lines = math.max(
          1,
          (constraints.maxHeight / typography.measuredLineHeight(style))
              .floor(),
        );
        final titleLines = showsTitle ? math.min(2, lines) : 0;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxHeight: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showsTitle)
                  Text(
                    title,
                    maxLines: titleLines,
                    overflow: TextOverflow.ellipsis,
                    style: style.copyWith(fontWeight: FontWeight.w800),
                  ),
                if (body.plain.isNotEmpty && lines > titleLines)
                  Text.rich(
                    styledTextSpan(body, style),
                    maxLines: lines - titleLines,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
