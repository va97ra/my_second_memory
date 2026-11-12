import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Время над рамкой: не под пальцем, потому что флажки стоят справа.
class DayTimelineRangeLabel extends StatelessWidget {
  const DayTimelineRangeLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: readableInkOn(color),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
