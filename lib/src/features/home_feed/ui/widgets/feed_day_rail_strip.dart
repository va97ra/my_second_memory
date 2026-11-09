import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/ui/memory_card/memory_card_paper.dart';
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
    return PaperSheet(
      child: Material(
        color: notebookCardSurface,
        elevation: 8,
        shadowColor: MemoryCardPaper.shadowColor(context),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: _radius),
        clipBehavior: Clip.antiAlias,
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
                    child: _RailDay(
                      day: scale.dayOf(index),
                      active: index == activeIndex,
                      own: index == 0,
                      todayColor: isSameDay(scale.dayOf(index), now)
                          ? todayColor
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailDay extends StatelessWidget {
  const _RailDay({
    required this.day,
    required this.active,
    required this.own,
    required this.todayColor,
  });

  final DateTime day;
  final bool active;
  final bool own;

  /// Есть только у сегодняшнего дня.
  final Color? todayColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final ink = active
        ? readableInkOn(AppPalette.accent)
        : day.weekday >= DateTime.saturday
            ? AppPalette.weekend
            : theme.colorScheme.onSurface;
    // Первое число подписано месяцем: по нему видно, что месяц сменился.
    final caption = day.day == 1
        ? DateFormat.MMM(locale).format(day)
        : DateFormat.E(locale).format(day);
    final today = todayColor;

    return DecoratedBox(
      // Черта над понедельником делит шкалу на недели.
      decoration: BoxDecoration(
        border: day.weekday == DateTime.monday
            ? const Border(top: BorderSide(color: AppPalette.muted))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active
                ? AppPalette.accent
                : own
                    ? AppPalette.accent.withValues(alpha: 0.16)
                    : null,
            borderRadius: BorderRadius.circular(6),
            border: today == null ? null : Border.all(color: today, width: 1.5),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    caption,
                    style: theme.textTheme.labelSmall?.copyWith(color: ink),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
