import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_labels.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';

/// Полоса карточки записки: цвет вида и мелко — вид, дата создания и отметка
/// о выполнении. Все подписи и цвет те же, что у карточек ленты.
class NoteCardStrip extends StatelessWidget {
  const NoteCardStrip({super.key, required this.item});

  static const height = 18.0;

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    final accent = memoryAccentColor(item);
    final locale = Localizations.localeOf(context).languageCode;
    final done = memoryDoneLabel(context, item);
    final style = TextStyle(
      color: readableInkOn(accent),
      fontSize: 8.5,
      fontWeight: FontWeight.w800,
      height: 1,
    );

    return ColoredBox(
      color: accent,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _Fitted(
                  alignment: Alignment.centerLeft,
                  text: '${item.type.label(locale)} ${memoryCreatedLabel(item)}',
                  style: style,
                ),
              ),
              if (done != null) ...[
                const SizedBox(width: 3),
                Expanded(
                  flex: 2,
                  child: _Fitted(
                    alignment: Alignment.centerRight,
                    text: done,
                    style: style,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Подпись ужимается целиком, а не обрывается многоточием.
class _Fitted extends StatelessWidget {
  const _Fitted({
    required this.alignment,
    required this.text,
    required this.style,
  });

  final Alignment alignment;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(text, maxLines: 1, style: style),
      );
}
