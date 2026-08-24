import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';


/// Число месяца в ячейке дня.
class DayNumber extends StatelessWidget {
  const DayNumber({super.key, 
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
    final palette = AppSurfacePalette.of(context);
    final content = Text(
      '$day',
      style: TextStyle(
        color: isSelected
            ? colors.onPrimary
            : isToday
                ? colors.onPrimary
                : color,
        fontSize: 12.5,
        fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w800,
        height: 1,
      ),
    );

    if (!isToday && !isSelected) {
      return content;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? colors.onPrimary.withValues(alpha: 0.18) : null,
        gradient: isSelected ? null : palette.accentGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: content,
      ),
    );
  }
}
