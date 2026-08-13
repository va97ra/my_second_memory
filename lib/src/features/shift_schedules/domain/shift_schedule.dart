class ShiftVacation {
  const ShiftVacation({
    required this.id,
    required this.startDate,
    required this.durationDays,
  }) : assert(durationDays > 0);

  final String id;
  final DateTime startDate;
  final int durationDays;

  DateTime get endDate =>
      _dateOnly(startDate).add(Duration(days: durationDays - 1));

  bool contains(DateTime date) {
    final checkedDate = _dateOnly(date);
    return !checkedDate.isBefore(_dateOnly(startDate)) &&
        !checkedDate.isAfter(endDate);
  }

  bool overlaps(ShiftVacation other) {
    return !_dateOnly(startDate).isAfter(other.endDate) &&
        !endDate.isBefore(_dateOnly(other.startDate));
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'startDate': _dateOnly(startDate).toIso8601String(),
        'durationDays': durationDays,
      };

  factory ShiftVacation.fromJson(Map<String, Object?> json) {
    final startDate = DateTime.parse(json['startDate'] as String);
    final storedDuration = json['durationDays'] as int? ?? 1;
    final durationDays = storedDuration > 0 ? storedDuration : 1;
    return ShiftVacation(
      id: json['id'] as String? ??
          '${_dateOnly(startDate).toIso8601String()}-$durationDays',
      startDate: startDate,
      durationDays: durationDays,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class ShiftAlarm {
  const ShiftAlarm({
    this.isEnabled = false,
    this.timeMinutes = 7 * 60,
    this.soundUri,
    this.soundName,
  });

  final bool isEnabled;
  final int timeMinutes;
  final String? soundUri;
  final String? soundName;

  ShiftAlarm copyWith({
    bool? isEnabled,
    int? timeMinutes,
    String? soundUri,
    String? soundName,
    bool clearSound = false,
  }) {
    return ShiftAlarm(
      isEnabled: isEnabled ?? this.isEnabled,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      soundUri: clearSound ? null : soundUri ?? this.soundUri,
      soundName: clearSound ? null : soundName ?? this.soundName,
    );
  }

  Map<String, Object?> toJson() => {
        'isEnabled': isEnabled,
        'timeMinutes': timeMinutes,
        'soundUri': soundUri,
        'soundName': soundName,
      };

  factory ShiftAlarm.fromJson(Map<String, Object?> json) {
    return ShiftAlarm(
      isEnabled: json['isEnabled'] as bool? ?? false,
      timeMinutes: json['timeMinutes'] as int? ?? 7 * 60,
      soundUri: json['soundUri'] as String?,
      soundName: json['soundName'] as String?,
    );
  }
}

class ShiftSchedule {
  const ShiftSchedule({
    required this.id,
    required this.organizationName,
    required this.colorValue,
    required this.startDate,
    required this.workDays,
    required this.restDays,
    this.isEnabled = true,
    this.alarms = const [ShiftAlarm(), ShiftAlarm()],
    this.vacations = const [],
  });

  final String id;
  final String organizationName;
  final int colorValue;
  final DateTime startDate;
  final int workDays;
  final int restDays;
  final bool isEnabled;
  final List<ShiftAlarm> alarms;
  final List<ShiftVacation> vacations;

  bool get supportsNextDayAlarm => workDays == 1 && restDays == 3;

  bool isWorkday(DateTime date) {
    if (!isEnabled || workDays <= 0 || restDays < 0) return false;

    final checkedDate = _dateOnly(date);
    final firstDate = _dateOnly(startDate);
    if (checkedDate.isBefore(firstDate)) return false;

    final cycleLength = workDays + restDays;
    if (cycleLength <= 0) return false;

    return checkedDate.difference(firstDate).inDays % cycleLength < workDays;
  }

  bool isVacationWorkday(DateTime date) {
    return isWorkday(date) &&
        vacations.any((vacation) => vacation.contains(date));
  }

  ShiftSchedule copyWith({
    String? id,
    String? organizationName,
    int? colorValue,
    DateTime? startDate,
    int? workDays,
    int? restDays,
    bool? isEnabled,
    List<ShiftAlarm>? alarms,
    List<ShiftVacation>? vacations,
  }) {
    return ShiftSchedule(
      id: id ?? this.id,
      organizationName: organizationName ?? this.organizationName,
      colorValue: colorValue ?? this.colorValue,
      startDate: startDate ?? this.startDate,
      workDays: workDays ?? this.workDays,
      restDays: restDays ?? this.restDays,
      isEnabled: isEnabled ?? this.isEnabled,
      alarms: alarms ?? this.alarms,
      vacations: vacations ?? this.vacations,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'organizationName': organizationName,
        'colorValue': colorValue,
        'startDate': _dateOnly(startDate).toIso8601String(),
        'workDays': workDays,
        'restDays': restDays,
        'isEnabled': isEnabled,
        'alarms': alarms.map((alarm) => alarm.toJson()).toList(),
        'vacations': vacations.map((vacation) => vacation.toJson()).toList(),
      };

  factory ShiftSchedule.fromJson(Map<String, Object?> json) {
    final storedAlarms = (json['alarms'] as List<Object?>?)
            ?.whereType<Map>()
            .map((entry) => ShiftAlarm.fromJson(entry.cast<String, Object?>()))
            .take(2)
            .toList() ??
        <ShiftAlarm>[];

    // Versions before 1.0.2 stored one alarm directly on the schedule.
    if (storedAlarms.isEmpty) {
      storedAlarms.add(
        ShiftAlarm(
          isEnabled: json['alarmEnabled'] as bool? ?? false,
          timeMinutes: json['alarmTimeMinutes'] as int? ?? 7 * 60,
          soundUri: json['alarmSoundUri'] as String?,
          soundName: json['alarmSoundName'] as String?,
        ),
      );
    }
    while (storedAlarms.length < 2) {
      storedAlarms.add(const ShiftAlarm());
    }
    final storedVacations = (json['vacations'] as List<Object?>?)
            ?.whereType<Map>()
            .map((entry) =>
                ShiftVacation.fromJson(entry.cast<String, Object?>()))
            .toList() ??
        <ShiftVacation>[];
    storedVacations.sort((a, b) => a.startDate.compareTo(b.startDate));

    return ShiftSchedule(
      id: json['id'] as String,
      organizationName: json['organizationName'] as String,
      colorValue: json['colorValue'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      workDays: json['workDays'] as int,
      restDays: json['restDays'] as int,
      isEnabled: json['isEnabled'] as bool? ?? true,
      alarms: List.unmodifiable(storedAlarms),
      vacations: List.unmodifiable(storedVacations),
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
