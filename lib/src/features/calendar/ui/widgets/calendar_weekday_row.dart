import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../state/calendar_month_data.dart';

/// Строка дней недели над сеткой месяца.
///
/// В блокнотной теме это семь отдельных плиток, в остальных — одна полоса:
/// бумага делится на карточки, а обычная тема держит сплошную шапку.
class CalendarWeekdayRow extends StatelessWidget {
  const CalendarWeekdayRow({super.key, required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final labels = calendarWeekdayLabels(locale);
    if (NotebookVisuals.maybeOf(context) != null) {
      return SizedBox(
        key: const ValueKey('calendar_weekdays'),
        height: 28,
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == labels.length - 1 ? 0 : 2,
                  ),
                  child: _tile(context, labels[index], index),
                ),
              ),
          ],
        ),
      );
    }

    final palette = AppSurfacePalette.of(context);
    return DecoratedBox(
      key: const ValueKey('calendar_weekdays'),
      decoration: BoxDecoration(
        gradient: palette.surfaceGradient(base: palette.weekdaySurface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++)
              Expanded(
                child: Center(
                  // Сплошная полоса набрана без разрядки: буквы в ней стоят
                  // ближе, чем на отдельных плитках.
                  child: _label(context, labels[index], index, spacing: 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, int index) {
    final palette = AppSurfacePalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.weekdaySurface.withValues(alpha: 0.96),
            palette.weekdaySurface,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: notebookSurfaceShadow(context, NotebookSurfaceDepth.tile),
      ),
      child: Center(child: _label(context, label, index)),
    );
  }

  /// Выходные набраны своим цветом.
  Widget _label(
    BuildContext context,
    String label,
    int index, {
    double? spacing,
  }) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: index >= 5
                ? const Color(0xFFEA580C)
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            letterSpacing: spacing,
          ),
    );
  }
}
