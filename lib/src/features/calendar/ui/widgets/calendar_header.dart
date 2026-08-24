import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'shift_legend_chip.dart';

/// Шапка календаря: заголовок, месяц со стрелками и графики смен, которые
/// его красят. Та же карточка, те же полосы и те же кегли, что и у ленты.
class CalendarHeader extends StatelessWidget {
  const CalendarHeader({
    super.key,
    required this.visibleMonth,
    required this.locale,
    required this.schedules,
    required this.onToday,
    required this.onChangeMonth,
  });

  final DateTime visibleMonth;
  final String locale;
  final List<ShiftSchedule> schedules;
  final VoidCallback onToday;
  final ValueChanged<int> onChangeMonth;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final legend = [
      for (final schedule in schedules)
        if (schedule.isEnabled) schedule,
    ];

    return NotebookPageHeader(
      cardKey: const ValueKey('calendar_header_card'),
      bands: [
        NotebookHeaderBand(
          child: Row(
            children: [
              // Домашняя вкладка: возвращаться некуда, но слот остаётся, чтобы
              // заголовок держал свою середину.
              const SizedBox(width: notebookHeaderSlot),
              Expanded(
                child: Text(
                  strings.calendar,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              IconButton(
                key: const ValueKey('calendar_today'),
                tooltip: strings.today,
                onPressed: onToday,
                icon: const Icon(Icons.today_rounded, size: 22),
                style: notebookIconButtonStyle(),
              ),
            ],
          ),
        ),
        NotebookHeaderBand(
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('calendar_previous_month'),
                tooltip: strings.previousMonth,
                onPressed: () => onChangeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 24),
                style: notebookIconButtonStyle(),
              ),
              Expanded(
                child: Text(
                  _monthLabel(),
                  key: const ValueKey('calendar_month_label'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                ),
              ),
              IconButton(
                key: const ValueKey('calendar_next_month'),
                tooltip: strings.nextMonth,
                onPressed: () => onChangeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 24),
                style: notebookIconButtonStyle(),
              ),
            ],
          ),
        ),
        if (legend.isNotEmpty)
          NotebookHeaderBand(
            // Плашка занимает одну разлинованную строку при обычном кегле;
            // крупному нужна вторая, иначе она вылезет за полосу.
            ruledRows: MediaQuery.textScalerOf(context).scale(1) <= 1.3 ? 1 : 2,
            child: SingleChildScrollView(
              key: const ValueKey('calendar_shift_legend'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final schedule in legend)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ShiftLegendChip(schedule: schedule),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Названия месяцев приходят из intl со строчной буквы в части языков.
  String _monthLabel() {
    final month = DateFormat('LLLL', locale).format(visibleMonth);
    final capitalized = month.isEmpty
        ? month
        : '${month[0].toUpperCase()}${month.substring(1)}';
    return '$capitalized ${visibleMonth.year}';
  }
}
