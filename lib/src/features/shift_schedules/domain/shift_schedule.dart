class ShiftSchedule {
  const ShiftSchedule({
    required this.id,
    required this.organizationName,
    required this.colorValue,
    required this.startDate,
    required this.workDays,
    required this.restDays,
    this.isEnabled = true,
  });

  final String id;
  final String organizationName;
  final int colorValue;
  final DateTime startDate;
  final int workDays;
  final int restDays;
  final bool isEnabled;

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
  }) {
    return ShiftSchedule(
      id: id ?? this.id,
      organizationName: organizationName ?? this.organizationName,
      colorValue: colorValue ?? this.colorValue,
      startDate: startDate ?? this.startDate,
      workDays: workDays ?? this.workDays,
      restDays: restDays ?? this.restDays,
      isEnabled: isEnabled ?? this.isEnabled,
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
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
