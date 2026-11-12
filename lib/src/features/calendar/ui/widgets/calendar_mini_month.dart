import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/calendar_month_data.dart';
import 'calendar_day_cell_surface.dart';
import 'calendar_mini_month_painter.dart';

/// Клетка годового вида: название месяца и его миниатюра. Нажатие открывает
/// месяц.
class CalendarMiniMonth extends StatelessWidget {
  const CalendarMiniMonth({
    super.key,
    required this.month,
    required this.locale,
    required this.data,
    required this.productionDays,
    required this.highlight,
    required this.today,
    required this.onOpen,
  });

  final DateTime month;
  final String locale;
  final CalendarMonthData data;
  final ProductionCalendar productionDays;
  final bool highlight;
  final DateTime today;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final name = DateFormat('LLLL', locale).format(month);
    final label =
        name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';
    final isCurrent = month.year == today.year && month.month == today.month;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => NotebookPressable(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(4),
        child: Semantics(
          button: true,
          label: '$label ${month.year}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название сжимается, а не растёт за четверть клетки: при
              // крупном шрифте системы миниатюре иначе не осталось бы места.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.24,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isCurrent ? calendarTodayColor(context) : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(child: _days()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _days() {
    return RepaintBoundary(
      child: NotebookPaperIsland(
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return CustomPaint(
              size: Size.infinite,
              painter: CalendarMiniMonthPainter(
                month: month,
                data: data,
                productionDays: productionDays,
                highlight: highlight,
                today: today,
                colors: theme.colorScheme,
                palette: AppSurfacePalette.of(context),
                todayColor: calendarTodayColor(context),
                numberStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ) ??
                    const TextStyle(fontWeight: FontWeight.w800),
              ),
            );
          },
        ),
      ),
    );
  }
}
