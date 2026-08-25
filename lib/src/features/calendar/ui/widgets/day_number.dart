import 'package:flutter/material.dart';

/// Число месяца в ячейке дня.
///
/// Сегодняшнее число крупнее прочих и обведено красным кольцом. Заливки у него
/// нет: в день открытия сегодня — ещё и выбранный день, и акцентная заливка
/// съедала бы его собственную примету. Чёрной рамки вокруг ячейки оказалось
/// мало — среди цветных дней она теряется, поэтому примета стоит на самом
/// числе, куда смотрят в первую очередь.
class DayNumber extends StatelessWidget {
  const DayNumber({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.color,
  });

  /// Кольцо вокруг сегодняшнего числа.
  static const todayRing = Color(0xFFD32020);

  final int day;
  final bool isToday;
  final bool isSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Text(
      '$day',
      style: TextStyle(
        color: isSelected && !isToday ? colors.onPrimary : color,
        fontSize: isToday ? 17 : 12.5,
        fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w800,
        height: 1,
      ),
    );

    if (isToday) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: todayRing, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: content,
        ),
      );
    }

    if (!isSelected) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: content,
      ),
    );
  }
}
