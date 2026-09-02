/// Что человек выбрал в листе времени и напоминания.
class TimeReminderDraft {
  const TimeReminderDraft({
    required this.timeMinutes,
    required this.reminderEnabled,
    required this.leadMinutes,
    required this.soundUri,
    required this.soundName,
  });

  /// Время записи от полуночи, или null, если время не задано.
  final int? timeMinutes;

  final bool reminderEnabled;

  /// За сколько минут до записи напомнить. Ноль — ровно в её время.
  final int leadMinutes;

  /// Свой звук напоминания. Null — системный.
  final String? soundUri;
  final String? soundName;
}
