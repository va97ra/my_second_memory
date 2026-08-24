import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'shift_schedule_summary_line.dart';

/// Содержимое карточки графика: название, рисунок и строки-пояснения.
class ShiftScheduleTileDetails extends StatelessWidget {
  const ShiftScheduleTileDetails({
    super.key,
    required this.schedule,
    required this.locale,
  });

  final ShiftSchedule schedule;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final dateText = DateFormat.yMMMd(locale).format(schedule.startDate);
    final alarms = _alarmLabels();
    final vacation = schedule.vacationToShow(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          schedule.organizationName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          '${schedule.workDays}/${schedule.restDays} · $dateText',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (alarms.isNotEmpty) ...[
          const SizedBox(height: 3),
          ShiftScheduleSummaryLine(
            icon: Icons.alarm_rounded,
            color: colors.primary,
            text: alarms.join(' · '),
          ),
        ],
        if (vacation != null) ...[
          const SizedBox(height: 3),
          ShiftScheduleSummaryLine(
            icon: Icons.beach_access_rounded,
            color: const Color(0xFF9A2442),
            text: _vacationSummary(strings, vacation),
            textKey: const ValueKey('shift_schedule_vacation_summary'),
          ),
        ],
      ],
    );
  }

  /// Времена включённых будильников. Второй показывается только там, где
  /// смена переходит через полночь.
  List<String> _alarmLabels() {
    final labels = <String>[];
    for (var index = 0; index < schedule.alarms.length; index++) {
      final alarm = schedule.alarms[index];
      if (!alarm.isEnabled) continue;
      if (index > 0 && !schedule.supportsNextDayAlarm) continue;
      final time = formatMinutesOfDay(alarm.timeMinutes);
      labels.add(index == 1 ? '+1 д. $time' : time);
    }
    return labels;
  }

  String _vacationSummary(AppStrings strings, ShiftVacation vacation) {
    final start = DateFormat.MMMd(locale).format(vacation.startDate);
    final end = DateFormat.MMMd(locale).format(vacation.endDate);
    final remaining = schedule.vacations.length - 1;
    final more = remaining > 0 ? ' · ${strings.moreVacations(remaining)}' : '';
    return '${strings.vacation}: $start — $end$more';
  }
}
