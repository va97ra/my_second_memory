import 'package:flutter/material.dart';

/// Число месяца в ячейке дня.
///
/// Сегодняшнее число крупнее прочих: заливки у него нет — его отмечает чёрная
/// обводка ячейки, — и размер остаётся единственной приметой внутри.
class DayNumber extends StatelessWidget {
  const DayNumber({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.color,
  });

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

    if (!isSelected || isToday) return content;

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
