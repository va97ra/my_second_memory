import 'moment_hits.dart';
import 'phrase_scan.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';

/// Вынимает повтор: «каждый день», «каждое утро», «по будням», «по
/// вторникам и четвергам», «каждое 10-е число», «каждый месяц», «каждый год».
void collectRepeat(PhraseScan scan, MomentHits hits) {
  for (final match in scan.take(_everyDayPart)) {
    hits.repeat = const PhraseRepeat(PhraseRepeatKind.daily);
    final part = match.namedGroup('p1') ??
        match.namedGroup('p2') ??
        match.namedGroup('p3') ??
        match.namedGroup('p4')!;
    hits.dayPart = part.startsWith('утр')
        ? DayPart.morning
        : part.startsWith('веч')
            ? DayPart.evening
            : DayPart.night;
  }
  if (scan.takes(_everyDay)) {
    hits.repeat = const PhraseRepeat(PhraseRepeatKind.daily);
  }
  if (scan.takes(_workdays)) {
    hits.repeat = const PhraseRepeat(PhraseRepeatKind.weekdays);
  }
  if (scan.takes(_weekends)) {
    hits.repeat = const PhraseRepeat(PhraseRepeatKind.weekly, weekdays: {6, 7});
  }
  for (final match in [
    ...scan.take(_everyWeekday),
    ...scan.take(_byWeekdays),
  ]) {
    final days = {
      for (final word in _weekdayWord.allMatches(match.namedGroup('list')!))
        weekdayFromWord(word.group(0)!),
    };
    final previous = hits.repeat;
    hits.repeat = PhraseRepeat(PhraseRepeatKind.weekly, weekdays: {
      ...days,
      if (previous?.kind == PhraseRepeatKind.weekly) ...previous!.weekdays,
    });
  }
  if (scan.takes(_everyWeek)) {
    hits.repeat ??= const PhraseRepeat(PhraseRepeatKind.weekly);
  }
  for (final match in scan.take(_everyMonthDay)) {
    final raw = match.namedGroup('d')!;
    final day = numberFromWords(raw) ?? ordinalFromWords(raw);
    if (day != null && day >= 1 && day <= 31) {
      hits.repeat = PhraseRepeat(PhraseRepeatKind.monthly, monthDay: day);
    }
  }
  if (scan.takes(_everyMonth)) {
    hits.repeat ??= const PhraseRepeat(PhraseRepeatKind.monthly);
  }
  if (scan.takes(_everyYear)) {
    hits.repeat = const PhraseRepeat(PhraseRepeatKind.yearly);
  }
}

/// Первый день повтора начиная с [from] включительно.
///
/// [base] — день, названный во фразе рядом с повтором: «каждый год 9 мая»
/// берёт из него число и месяц, «каждый месяц» без числа — число.
DateTime firstRepeatDay(
  PhraseRepeat repeat, {
  required DateTime base,
  required DateTime from,
}) {
  bool fits(DateTime day) => switch (repeat.kind) {
        PhraseRepeatKind.daily => true,
        PhraseRepeatKind.weekdays => day.weekday <= DateTime.friday,
        PhraseRepeatKind.weekly =>
          (repeat.weekdays.isEmpty ? {base.weekday} : repeat.weekdays)
              .contains(day.weekday),
        PhraseRepeatKind.monthly => day.day == _monthDayIn(day, repeat, base),
        PhraseRepeatKind.yearly =>
          day.month == base.month && day.day == _monthDayIn(day, null, base),
      };
  var day = DateTime(from.year, from.month, from.day);
  // Год — самый длинный шаг повтора; 29 февраля ждёт не дольше четырёх лет.
  for (var i = 0; i < 366 * 4 + 1; i++) {
    if (fits(day)) return day;
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return DateTime(from.year, from.month, from.day);
}

/// Число месяца, на которое выпадает повтор: 31-е в коротком месяце — его
/// последний день.
int _monthDayIn(DateTime day, PhraseRepeat? repeat, DateTime base) {
  final wanted = repeat?.monthDay ?? base.day;
  final lastDay = DateTime(day.year, day.month + 1, 0).day;
  return wanted > lastDay ? lastDay : wanted;
}

const _accusativeDays =
    'понедельник|вторник|среду|четверг|пятницу|субботу|воскресенье';
const _dativeDays =
    'понедельникам|вторникам|средам|четвергам|пятницам|субботам|воскресеньям';

final _everyDay = phrasePattern('$wordStart(?:каждый\\s+день|ежедневно'
    '|каждые\\s+сутки|изо\\s+дня\\s+в\\s+день)$wordEnd');

final _everyDayPart = phrasePattern('$wordStart(?:каждое\\s+(?<p1>утро)'
    '|каждый\\s+(?<p2>вечер)|каждую\\s+(?<p4>ночь)'
    '|по\\s+(?<p3>утрам|вечерам|ночам))$wordEnd');

final _workdays = phrasePattern('$wordStart(?:по\\s+будням|в\\s+будни'
    '|каждый\\s+будний\\s+день|по\\s+рабочим\\s+дням|в\\s+рабочие\\s+дни)'
    '$wordEnd');

final _weekends =
    phrasePattern('$wordStart(?:по\\s+выходным|каждые\\s+выходные)$wordEnd');

final _everyWeekday = phrasePattern('$wordStartкажд(?:ый|ую|ое)\\s+'
    '(?<list>(?:$_accusativeDays)(?:\\s*(?:,|и)\\s*(?:кажд(?:ый|ую|ое)\\s+)?'
    '(?:$_accusativeDays))*)$wordEnd');

final _byWeekdays = phrasePattern('$wordStartпо\\s+'
    '(?<list>(?:$_dativeDays)(?:\\s*(?:,|и)\\s*(?:по\\s+)?(?:$_dativeDays))*)'
    '$wordEnd');

final _weekdayWord =
    phrasePattern('$wordStart(?:$_dativeDays|$_accusativeDays)$wordEnd');

final _everyWeek = phrasePattern('$wordStart(?:каждую\\s+неделю|еженедельно'
    '|раз\\s+в\\s+неделю)$wordEnd');

final _everyMonthDay = phrasePattern('$wordStartкажд(?:ое|ого|ый)\\s+'
    '(?<d>$ordinalPattern|$numberPattern)(?:\\s*-?\\s*(?:е|го|ое))?'
    '\\s+числ[оа]$wordEnd');

final _everyMonth = phrasePattern('$wordStart(?:каждый\\s+месяц|ежемесячно'
    '|раз\\s+в\\s+месяц)$wordEnd');

final _everyYear = phrasePattern('$wordStart(?:каждый\\s+год|ежегодно'
    '|раз\\s+в\\s+год)$wordEnd');

/// Повтор, который подразумевается без слов «каждый год»: день рождения и
/// годовщина — раз в год, подписка, квартплата и кредит — раз в месяц
/// (просьба владельца 9 октября 2026). Повтор виден в ответе Джарвиса и
/// отменяется вместе с записью.
PhraseRepeat? impliedRepeat(String title, DateTime date) {
  final work = normalizePhrase(title);
  if (isAnniversary(title)) return const PhraseRepeat(PhraseRepeatKind.yearly);
  if (_monthly.hasMatch(work)) {
    return PhraseRepeat(PhraseRepeatKind.monthly, monthDay: date.day);
  }
  return null;
}

/// День рождения, годовщина, юбилей, именины — о них стоит сказать заранее.
bool isAnniversary(String title) => _yearly.hasMatch(normalizePhrase(title));

final _yearly = phrasePattern('$wordStart(?:день\\s+рождени|днюх|годовщин'
    '|юбиле|именин)');
final _monthly = phrasePattern('$wordStart(?:подписк|квартплат|коммуналк'
    '|ипотек|кредит)');
