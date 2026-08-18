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
  final groups = <List<ShiftSchedule>>[];
  for (final schedule in schedules) {
    List<ShiftSchedule>? matchingGroup;
    for (final group in groups) {
      if (group.any((existing) => _isSameCalendar(existing, schedule))) {
        matchingGroup = group;
        break;
      }
    }
    if (matchingGroup == null) {
      groups.add([schedule]);
    } else {
      matchingGroup.add(schedule);
    }
  }

  final deduplicated = <ShiftSchedule>[];
  final duplicateIds = <String>{};
  for (final group in groups) {
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

bool _isSameCalendar(ShiftSchedule left, ShiftSchedule right) {
  return left.colorValue == right.colorValue &&
      left.workDays == right.workDays &&
      left.restDays == right.restDays &&
      left.isEnabled == right.isEnabled &&
      _cyclePhase(left) == _cyclePhase(right) &&
      _namesLikelyMatch(left.organizationName, right.organizationName);
}

int _cyclePhase(ShiftSchedule schedule) {
  final cycleLength = schedule.workDays + schedule.restDays;
  if (cycleLength <= 0) return 0;
  final start = schedule.startDate;
  final dayNumber = DateTime.utc(start.year, start.month, start.day)
      .difference(DateTime.utc(1970))
      .inDays;
  return ((dayNumber % cycleLength) + cycleLength) % cycleLength;
}

bool _namesLikelyMatch(String left, String right) {
  return _normalizeName(left) == _normalizeName(right);
}

String _normalizeName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
