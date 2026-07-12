class ShiftSchedule {
  const ShiftSchedule({
    required this.id,
    required this.organizationName,
    required this.colorValue,
    required this.startDate,
    required this.workDays,
    required this.restDays,
    this.isEnabled = true,
    this.alarmEnabled = false,
    this.alarmTimeMinutes = 7 * 60,
    this.alarmSoundUri,
    this.alarmSoundName,
  });

  final String id;
  final String organizationName;
  final int colorValue;
  final DateTime startDate;
  final int workDays;
  final int restDays;
  final bool isEnabled;
  final bool alarmEnabled;
  final int alarmTimeMinutes;
  final String? alarmSoundUri;
  final String? alarmSoundName;

  bool isWorkday(DateTime date) {
    if (!isEnabled || workDays <= 0 || restDays < 0) {
      return false;
    }

    final checkedDate = _dateOnly(date);
    final firstDate = _dateOnly(startDate);
    if (checkedDate.isBefore(firstDate)) {
      return false;
    }

    final cycleLength = workDays + restDays;
    if (cycleLength <= 0) {
      return false;
    }

    final offset = checkedDate.difference(firstDate).inDays % cycleLength;
    return offset < workDays;
  }

  ShiftSchedule copyWith({
    String? id,
    String? organizationName,
    int? colorValue,
    DateTime? startDate,
    int? workDays,
    int? restDays,
    bool? isEnabled,
    bool? alarmEnabled,
    int? alarmTimeMinutes,
    String? alarmSoundUri,
    String? alarmSoundName,
    bool clearAlarmSound = false,
  }) {
    return ShiftSchedule(
      id: id ?? this.id,
      organizationName: organizationName ?? this.organizationName,
      colorValue: colorValue ?? this.colorValue,
      startDate: startDate ?? this.startDate,
      workDays: workDays ?? this.workDays,
      restDays: restDays ?? this.restDays,
      isEnabled: isEnabled ?? this.isEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      alarmTimeMinutes: alarmTimeMinutes ?? this.alarmTimeMinutes,
      alarmSoundUri:
          clearAlarmSound ? null : alarmSoundUri ?? this.alarmSoundUri,
      alarmSoundName:
          clearAlarmSound ? null : alarmSoundName ?? this.alarmSoundName,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'organizationName': organizationName,
      'colorValue': colorValue,
      'startDate': _dateOnly(startDate).toIso8601String(),
      'workDays': workDays,
      'restDays': restDays,
      'isEnabled': isEnabled,
      'alarmEnabled': alarmEnabled,
      'alarmTimeMinutes': alarmTimeMinutes,
      'alarmSoundUri': alarmSoundUri,
      'alarmSoundName': alarmSoundName,
    };
  }

  factory ShiftSchedule.fromJson(Map<String, Object?> json) {
    return ShiftSchedule(
      id: json['id'] as String,
      organizationName: json['organizationName'] as String,
      colorValue: json['colorValue'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      workDays: json['workDays'] as int,
      restDays: json['restDays'] as int,
      isEnabled: json['isEnabled'] as bool? ?? true,
      alarmEnabled: json['alarmEnabled'] as bool? ?? false,
      alarmTimeMinutes: json['alarmTimeMinutes'] as int? ?? 7 * 60,
      alarmSoundUri: json['alarmSoundUri'] as String?,
      alarmSoundName: json['alarmSoundName'] as String?,
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
