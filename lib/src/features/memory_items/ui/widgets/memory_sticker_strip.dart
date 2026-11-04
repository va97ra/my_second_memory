import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_labels.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import '../../../../shared/ui/memory_card/sticker_strip.dart';

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
    return StickerStrip(
      accent: memoryAccentColor(item),
      label: '${memoryKindLabel(context, item)} $_stampLabel'.trim(),
      trailingLabel: memoryDoneLabel(context, item),
    );
  }
}
