part of '../shift_schedules_screen.dart';

class _ShiftScheduleTile extends StatelessWidget {
  const _ShiftScheduleTile({
    required this.schedule,
    required this.locale,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final ShiftSchedule schedule;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(schedule.colorValue);
    final dateText = DateFormat.yMMMd(locale).format(schedule.startDate);
    final visibleVacation = _visibleVacation(schedule.vacations);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onEdit,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: schedule.isEnabled
                    ? color.withValues(alpha: 0.34)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
              color: schedule.isEnabled
                  ? color.withValues(alpha: 0.1)
                  : Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.92),
              boxShadow: notebookSurfaceShadow(
                context,
                NotebookSurfaceDepth.card,
              ).isNotEmpty
                  ? notebookSurfaceShadow(
                      context,
                      NotebookSurfaceDepth.card,
                    )
                  : [
                      BoxShadow(
                        color: color.withValues(
                          alpha: schedule.isEnabled ? 0.1 : 0,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(width: 38, height: 38),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.organizationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${schedule.workDays}/${schedule.restDays} · $dateText',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (schedule.alarms.asMap().entries.any((entry) =>
                            entry.value.isEnabled &&
                            (entry.key == 0 ||
                                schedule.supportsNextDayAlarm))) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.alarm_rounded,
                                size: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  schedule.alarms
                                      .asMap()
                                      .entries
                                      .where((entry) =>
                                          entry.value.isEnabled &&
                                          (entry.key == 0 ||
                                              schedule.supportsNextDayAlarm))
                                      .map((entry) => entry.key == 1
                                          ? '+1 д. ${_formatMinutes(entry.value.timeMinutes)}'
                                          : _formatMinutes(
                                              entry.value.timeMinutes))
                                      .join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (visibleVacation != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.beach_access_rounded,
                                size: 15,
                                color: Color(0xFF9A2442),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _vacationSummary(
                                    context,
                                    visibleVacation,
                                  ),
                                  key: const ValueKey(
                                    'shift_schedule_vacation_summary',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: const Color(0xFF9A2442),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Switch(
                    value: schedule.isEnabled,
                    onChanged: (_) => onToggle(),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      }
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(AppStrings.of(context).editShiftSchedule),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppStrings.of(context).delete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ShiftVacation? _visibleVacation(List<ShiftVacation> vacations) {
    if (vacations.isEmpty) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final vacation in vacations) {
      if (vacation.contains(today)) return vacation;
    }
    for (final vacation in vacations) {
      if (vacation.startDate.isAfter(today)) return vacation;
    }
    return null;
  }

  String _vacationSummary(
    BuildContext context,
    ShiftVacation vacation,
  ) {
    final strings = AppStrings.of(context);
    final start = DateFormat.MMMd(locale).format(vacation.startDate);
    final end = DateFormat.MMMd(locale).format(vacation.endDate);
    final remaining = schedule.vacations.length - 1;
    final more = remaining > 0 ? ' · ${strings.moreVacations(remaining)}' : '';
    return '${strings.vacation}: $start — $end$more';
  }
}
