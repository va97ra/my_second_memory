import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// День на шкале: день недели или месяц у первого числа, само число,
/// отметка своего дня и сегодняшнего.
class FeedDayRailDay extends StatelessWidget {
  const FeedDayRailDay({
    super.key,
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
    final accent = theme.colorScheme.primary;
    final locale = Localizations.localeOf(context).languageCode;
    final ink = active
        ? theme.colorScheme.onPrimary
        : day.weekday >= DateTime.saturday
            ? AppThemeColors.of(context)[AppColorRole.weekend]
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
                ? accent
                : own
                    ? accent.withValues(alpha: 0.16)
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
