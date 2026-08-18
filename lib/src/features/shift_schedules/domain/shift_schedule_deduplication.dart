import 'dart:convert';

import 'shift_schedule.dart';

class ShiftScheduleDeduplication {
  const ShiftScheduleDeduplication({
    required this.schedules,
    required this.duplicateIds,
  });

  final List<ShiftSchedule> schedules;
  final Set<String> duplicateIds;
}

/// Collapses copies of the same repeating schedule that were created on
/// different devices before schedule synchronization was enabled.
ShiftScheduleDeduplication deduplicateShiftSchedules(
  Iterable<ShiftSchedule> schedules,
) {
  final groups = <String, List<ShiftSchedule>>{};
  for (final schedule in schedules) {
    groups.putIfAbsent(_identityOf(schedule), () => []).add(schedule);
  }

  final deduplicated = <ShiftSchedule>[];
  final duplicateIds = <String>{};
  for (final group in groups.values) {
    if (group.length == 1) {
      deduplicated.add(group.single);
      continue;
    }

    final canonicalId = group
        .map((schedule) => schedule.id)
        .reduce((left, right) => left.compareTo(right) <= 0 ? left : right);
    var newest = group.first;
    for (final candidate in group.skip(1)) {
      final byTime = candidate.syncUpdatedAt.compareTo(newest.syncUpdatedAt);
      if (byTime > 0 ||
          (byTime == 0 && candidate.id.compareTo(newest.id) < 0)) {
        newest = candidate;
      }
    }

    deduplicated.add(
      newest.id == canonicalId ? newest : newest.copyWith(id: canonicalId),
    );
    duplicateIds.addAll(
      group.map((schedule) => schedule.id).where((id) => id != canonicalId),
    );
  }

  return ShiftScheduleDeduplication(
    schedules: List.unmodifiable(deduplicated),
    duplicateIds: Set.unmodifiable(duplicateIds),
  );
}

String _identityOf(ShiftSchedule schedule) {
  final start = schedule.startDate;
  final vacations = [...schedule.vacations]..sort((left, right) {
      final byStart = left.startDate.compareTo(right.startDate);
      return byStart != 0
          ? byStart
          : left.durationDays.compareTo(right.durationDays);
    });
  return jsonEncode({
    'organization': schedule.organizationName
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase(),
    'colorValue': schedule.colorValue,
    'startDate': '${start.year}-${start.month}-${start.day}',
    'workDays': schedule.workDays,
    'restDays': schedule.restDays,
    'isEnabled': schedule.isEnabled,
    'alarms': [
      for (final alarm in schedule.alarms)
        {
          'isEnabled': alarm.isEnabled,
          'timeMinutes': alarm.timeMinutes,
          'soundUri': alarm.soundUri,
          'soundName': alarm.soundName,
        },
    ],
    'vacations': [
      for (final vacation in vacations)
        {
          'startDate': '${vacation.startDate.year}-'
              '${vacation.startDate.month}-${vacation.startDate.day}',
          'durationDays': vacation.durationDays,
        },
    ],
  });
}
