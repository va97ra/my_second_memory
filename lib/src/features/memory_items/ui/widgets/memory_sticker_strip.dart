import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_labels.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';

/// Какая дата написана на полосе. Записке важно, когда её создали, делу в ленте
/// дня — во сколько оно, а в списке всех дат — ещё и какого числа.
enum StickerStamp { created, time, dayAndTime }

/// Цветная полоса карточки: мелко вид, дата и отметка о выполнении. Подписи и цвет
/// те же, что у остальных карточек.
class MemoryStickerStrip extends StatelessWidget {
  const MemoryStickerStrip({
    super.key,
    required this.item,
    required this.stamp,
  });

  final MemoryItem item;
  final StickerStamp stamp;

  String get _stampLabel => switch (stamp) {
        StickerStamp.created => memoryCreatedLabel(item),
        StickerStamp.time => item.timeMinutes == null
            ? ''
            : formatMinutesOfDay(item.timeMinutes!),
        StickerStamp.dayAndTime => memoryDayAndTimeLabel(item),
      };

  @override
  Widget build(BuildContext context) {
    final accent = memoryAccentColor(item);
    final done = memoryDoneLabel(context, item);
    final style = TextStyle(
      color: readableInkOn(accent),
      fontSize: 8.5,
      fontWeight: FontWeight.w800,
      height: 1,
    );

    return ColoredBox(
      color: accent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _Fitted(
                alignment: Alignment.centerLeft,
                text: '${memoryKindLabel(context, item)} $_stampLabel'.trim(),
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
