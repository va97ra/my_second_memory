/// Что человек выбрал в листе времени и напоминания.
class TimeReminderDraft {
  const TimeReminderDraft({
    required this.timeMinutes,
    required this.reminderEnabled,
    required this.soundUri,
    required this.soundName,
  });

  /// Время записи от полуночи, или null, если время не задано.
  final int? timeMinutes;

  final bool reminderEnabled;

  /// Свой звук напоминания. Null — системный.
  final String? soundUri;
  final String? soundName;
}
