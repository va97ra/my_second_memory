import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_paper.dart';
import 'feed_day_rail_day.dart';
import 'feed_day_rail_paper.dart';
import 'feed_day_scale.dart';

/// Сама шкала: бумажная полоса с днями. Рисует только те дни, что видны.
class FeedDayRailStrip extends StatelessWidget {
  const FeedDayRailStrip({
    super.key,
    required this.scale,
    required this.activeIndex,
    required this.todayColor,
  });

  static const _radius = BorderRadius.horizontal(left: Radius.circular(8));

  final FeedDayScale scale;

  /// День под пальцем. Пусто, пока палец не на шкале.
  final int? activeIndex;

  /// Цвет отметки сегодня. Спрашивают снаружи листа: внутри тема всегда светлая.
  final Color todayColor;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cell = scale.cellExtent;
    return FeedDayRailPaper(
      radius: _radius,
      elevation: 8,
      child: Ink(
        decoration: MemoryCardPaper.surface(_radius),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              for (var index = scale.indexAt(-cell);
                  index <= scale.indexAt(constraints.maxHeight + cell);
                  index++)
                Positioned(
                  key: ValueKey(index),
                  left: 0,
                  right: 0,
                  top: scale.centerOf(index) - cell / 2,
                  height: cell,
                  child: FeedDayRailDay(
                    day: scale.dayOf(index),
                    active: index == activeIndex,
                    own: index == 0,
                    todayColor:
                        isSameDay(scale.dayOf(index), now) ? todayColor : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
