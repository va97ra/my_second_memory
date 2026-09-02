/// Что человек выбрал в листе времени и напоминания.
class TimeReminderDraft {
  const TimeReminderDraft({
    required this.timeMinutes,
    required this.reminderEnabled,
    required this.reminderMinutes,
    required this.soundUri,
    required this.soundName,
  });

  /// Время записи от полуночи, или null, если время не задано.
  final int? timeMinutes;

  final bool reminderEnabled;

  /// Во сколько напомнить, от полуночи того же дня.
  ///
  /// Часами, а не форой: «за десять минут» и «за час» — лишь два значения из
  /// многих, а часы дают любое.
  final int? reminderMinutes;

  /// Свой звук напоминания. Null — системный.
  final String? soundUri;
  final String? soundName;
}
