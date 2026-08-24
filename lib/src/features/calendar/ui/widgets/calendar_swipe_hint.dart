import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Подсказка под сеткой: календарь листается пальцем.
class CalendarSwipeHint extends StatelessWidget {
  const CalendarSwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppSurfacePalette.of(context);

    return DecoratedBox(
      key: const ValueKey('calendar_hint'),
      decoration: BoxDecoration(
        color: palette.raisedSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderStart),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.swipe_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.of(context).calendarTapHint,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
