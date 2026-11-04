import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'calendar_day_cell.dart';

/// Отклик дня на палец и мышь: плитка сжимается общим [PressPulse], а под курсором
/// чуть подкрашивается. Выбранного дня в календаре нет: нажатие просто открывает
/// день и не оставляет следа.
class CalendarDayPressEffect extends StatefulWidget {
  const CalendarDayPressEffect({super.key, required this.child});

  final Widget child;

  @override
  State<CalendarDayPressEffect> createState() => _CalendarDayPressEffectState();
}

class _CalendarDayPressEffectState extends State<CalendarDayPressEffect> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressPulse(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _hovered ? 0.07 : 0),
          duration: PressPulse.duration,
          child: widget.child,
          builder: (context, tint, child) => Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CalendarDayCell.cornerRadius),
              color: Colors.black.withValues(alpha: tint),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
