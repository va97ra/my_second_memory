import 'package:flutter/material.dart';

/// Число месяца в ячейке дня.
///
/// Все числа одного размера. Сегодняшнее — крупнее и обведено красным по
/// контуру: рамка вокруг него спорила с рамкой ячейки и с шапкой графика, а
/// обводка по самой цифре видна на любом фоне и ничего не занимает.
class DayNumber extends StatelessWidget {
  const DayNumber({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.color,
  });

  /// Обводка сегодняшнего числа.
  static const todayRing = Color(0xFFD32020);

  /// Размер обычного числа и сегодняшнего.
  static const fontSize = 12.5;
  static const todayFontSize = 17.0;

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
        fontSize: isToday ? todayFontSize : fontSize,
        fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w800,
        height: 1,
        // Обводка собрана тенями по четырём сторонам: у текста нет способа
        // нарисовать контур и заливку одним проходом.
        shadows: isToday ? _ring : null,
      ),
    );

    if (isToday || !isSelected) return content;

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

  static const _ring = <Shadow>[
    Shadow(color: todayRing, offset: Offset(-1.4, 0)),
    Shadow(color: todayRing, offset: Offset(1.4, 0)),
    Shadow(color: todayRing, offset: Offset(0, -1.4)),
    Shadow(color: todayRing, offset: Offset(0, 1.4)),
    Shadow(color: todayRing, offset: Offset(-1, -1)),
    Shadow(color: todayRing, offset: Offset(1, -1)),
    Shadow(color: todayRing, offset: Offset(-1, 1)),
    Shadow(color: todayRing, offset: Offset(1, 1)),
  ];
}
