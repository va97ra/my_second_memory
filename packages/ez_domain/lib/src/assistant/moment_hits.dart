/// Часть суток, названная словом: «утром», «после обеда», «ночью».
enum DayPart { morning, afternoon, afterLunch, evening, night }

/// Время, названное во фразе, ещё без поправки на часть суток: «в 7» может
/// оказаться и утром, и вечером.
class TimeHit {
  const TimeHit(this.hour, this.minute, this.qualifier);

  final int hour;
  final int minute;

  /// «утра», «дня», «вечера», «ночи» — если сказано рядом с часом.
  final String? qualifier;
}

/// Как часто повторяется дело, названное во фразе.
enum PhraseRepeatKind { daily, weekdays, weekly, monthly, yearly }

/// Повтор, названный во фразе: «по вторникам и четвергам», «каждое 10-е».
class PhraseRepeat {
  const PhraseRepeat(this.kind, {this.weekdays = const {}, this.monthDay});

  final PhraseRepeatKind kind;

  /// Дни недели для [PhraseRepeatKind.weekly], понедельник — 1.
  final Set<int> weekdays;

  /// Число месяца для [PhraseRepeatKind.monthly], если названо.
  final int? monthDay;
}

/// Всё о моменте, что нашлось во фразе.
class MomentHits {
  PhraseRepeat? repeat;
  final dates = <DateTime>[];

  /// «через 2 часа» — сразу и дата, и время.
  final relative = <Duration>[];
  final times = <TimeHit>[];
  DayPart? dayPart;

  /// «весь день», «время не важно».
  bool allDay = false;

  /// «без даты», «когда-нибудь».
  bool noDate = false;

  /// «на следующей неделе» без дня — дату надо уточнить.
  bool vagueDate = false;

  /// Сколько займёт: «на полчаса», «минут на 20», «с 12 до 13».
  int? durationMinutes;
}
