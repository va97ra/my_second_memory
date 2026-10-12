import 'moment_hits.dart';
import 'phrase_scan.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';

/// Вынимает «через 2 часа», «через полчаса», «через 15 минут».
void collectRelativeTime(PhraseScan scan, MomentHits hits) {
  for (final match in scan.take(_relativeTime)) {
    final unit = match.namedGroup('u')!;
    final raw = match.namedGroup('n');
    if (unit == 'полчаса') {
      hits.relative.add(const Duration(minutes: 30));
      continue;
    }
    final isHour = unit.startsWith('час');
    if (raw == 'полтора' || raw == 'полторы') {
      hits.relative.add(
          isHour ? const Duration(minutes: 90) : const Duration(seconds: 90));
      continue;
    }
    final count = raw == null ? 1 : numberFromWords(raw);
    if (count == null) continue;
    hits.relative
        .add(isHour ? Duration(hours: count) : Duration(minutes: count));
  }
}

/// Вынимает длительность: «с 12 до 13» (а с ним и начало), «на полчаса»,
/// «минут на 20», «на полтора часа», «на час». «На 2 часа» не берётся:
/// это бывает и временем — «на 2 часа дня».
void collectDuration(PhraseScan scan, MomentHits hits) {
  for (final match in scan.take(_range)) {
    final h1 = int.parse(match.namedGroup('h1')!);
    final m1 = int.parse(match.namedGroup('m1') ?? '0');
    final h2 = int.parse(match.namedGroup('h2')!);
    final m2 = int.parse(match.namedGroup('m2') ?? '0');
    if (h1 > 23 || h2 > 23 || m1 > 59 || m2 > 59) continue;
    hits.times.add(TimeHit(h1, m1, match.namedGroup('q')));
    var length = (h2 * 60 + m2) - (h1 * 60 + m1);
    if (length <= 0) length += 12 * 60;
    hits.durationMinutes = length;
  }
  if (hits.durationMinutes != null) return;
  for (final match in scan.take(_lengthMinutes)) {
    final count =
        numberFromWords(match.namedGroup('n') ?? match.namedGroup('n2')!);
    if (count != null && count > 0) hits.durationMinutes = count;
  }
  if (scan.takes(_halfHourLength)) hits.durationMinutes = 30;
  if (scan.takes(_hourAndHalfLength)) hits.durationMinutes = 90;
  if (scan.takes(_hourLength)) hits.durationMinutes = 60;
}

/// Вынимает время суток: «в 10», «в 7:30», «в половине восьмого», «в полдень»,
/// «7 вечера» — и часть суток: «утром», «после обеда».
void collectTimes(PhraseScan scan, MomentHits hits) {
  for (final match in scan.take(_noon)) {
    hits.times.add(TimeHit(12, 0, match.namedGroup('q') ?? 'дня'));
  }
  for (final match in scan.take(_half)) {
    final hour = ordinalFromWords(match.namedGroup('h')!);
    if (hour == null || hour < 1 || hour > 12) continue;
    // «в половине восьмого» — это 7:30.
    hits.times
        .add(TimeHit(hour == 1 ? 12 : hour - 1, 30, match.namedGroup('q')));
  }
  for (final match in scan.take(_clock)) {
    final hour = int.parse(match.namedGroup('h')!);
    final minute = int.parse(match.namedGroup('m')!);
    if (hour > 23 || minute > 59) continue;
    hits.times.add(TimeHit(hour, minute, match.namedGroup('q')));
  }
  for (final match in scan.take(_oneOClock)) {
    hits.times.add(TimeHit(1, 0, match.namedGroup('q') ?? 'дня'));
  }
  for (final match in scan.take(_hourWithPreposition)) {
    final hour = numberFromWords(match.namedGroup('h')!);
    final rawMinute = match.namedGroup('m');
    final minute = rawMinute == null ? 0 : numberFromWords(rawMinute);
    if (hour == null || minute == null || hour > 23 || minute > 59) continue;
    hits.times.add(TimeHit(hour, minute, match.namedGroup('q')));
  }
  for (final match in scan.take(_hourWithNa)) {
    final hour = numberFromWords(match.namedGroup('h')!);
    final rawMinute = match.namedGroup('m');
    final minute = rawMinute == null ? 0 : numberFromWords(rawMinute);
    if (hour == null || minute == null || hour > 23 || minute > 59) continue;
    hits.times.add(TimeHit(
        hour, minute, match.namedGroup('q') ?? match.namedGroup('q2')));
  }
  for (final match in scan.take(_hourWithQualifier)) {
    final hour = numberFromWords(match.namedGroup('h')!);
    if (hour == null || hour > 23) continue;
    hits.times.add(TimeHit(hour, 0, match.namedGroup('q')));
  }
  for (final match in scan.take(_dayPart)) {
    hits.dayPart = _dayPartOf(match.namedGroup('p')!);
  }
}

/// Ответ на «во сколько?» одним числом: «10», «десять», «10 30», «семь вечера».
TimeHit? bareTime(String work) {
  final match = _bareTime.firstMatch(work.trim());
  if (match == null) return null;
  final hour = numberFromWords(match.namedGroup('h')!);
  final rawMinute = match.namedGroup('m');
  final minute = rawMinute == null ? 0 : numberFromWords(rawMinute);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return TimeHit(hour, minute, match.namedGroup('q'));
}

/// Час для «утром», «днём», «вечером» без точного времени.
int dayPartMinutes(DayPart part) => switch (part) {
      DayPart.morning => 9 * 60,
      DayPart.afternoon => 13 * 60,
      DayPart.afterLunch => 15 * 60,
      DayPart.evening => 19 * 60,
      DayPart.night => 23 * 60,
    };

/// Время в минутах от полуночи: «в 7» и «в 7 вечера» становятся 19:00, если
/// так велит часть суток или если утро этого дня уже прошло.
int resolveTime(TimeHit hit, DayPart? part, DateTime date, DateTime now) {
  var hour = hit.hour;
  switch (hit.qualifier) {
    case 'утра':
      if (hour == 12) hour = 0;
    case 'дня':
      if (hour >= 1 && hour <= 6) hour += 12;
    case 'вечера':
      if (hour < 12) hour += 12;
    case 'ночи':
      if (hour == 12) {
        hour = 0;
      } else if (hour >= 9 && hour < 12) {
        hour += 12;
      }
    default:
      hour = _hourByDayPart(hour, hit.minute, part, date, now);
  }
  return (hour % 24) * 60 + hit.minute;
}

int _hourByDayPart(
    int hour, int minute, DayPart? part, DateTime date, DateTime now) {
  if (part == DayPart.evening && hour < 12) return hour + 12;
  if ((part == DayPart.afternoon || part == DayPart.afterLunch) &&
      hour >= 1 &&
      hour <= 6) {
    return hour + 12;
  }
  if (part == DayPart.night && hour >= 9 && hour < 12) return hour + 12;
  if (part != null) return hour;
  // «в 3» — это день: в три ночи дела назначают, называя ночь.
  if (hour >= 1 && hour <= 6) return hour + 12;
  final sameDay =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (hour >= 7 && hour <= 11 && sameDay) {
    // «в 10», а сейчас уже 14:00, — значит 22:00.
    final morning = DateTime(now.year, now.month, now.day, hour, minute);
    if (!morning.isAfter(now)) return hour + 12;
  }
  return hour;
}

DayPart _dayPartOf(String word) {
  if (word.contains('утр')) return DayPart.morning;
  if (word.contains('после')) return DayPart.afterLunch;
  if (word.contains('ден') || word.contains('дн') || word.contains('обед')) {
    return DayPart.afternoon;
  }
  if (word.contains('веч')) return DayPart.evening;
  return DayPart.night;
}

const _qualifier = '(?:\\s+(?<q>утра|дня|вечера|ночи))?';

final _relativeTime = phrasePattern('$wordStart(?:через|спустя)\\s+'
    '(?:(?<n>$numberPattern|пару|полтора|полторы)\\s+)?'
    '(?<u>полчаса|минуту|минуты|минут|часа|часов|час)$wordEnd');

final _noon =
    phrasePattern('$wordStart(?:в|к|до)\\s+полдень$_qualifier$wordEnd');

final _half = phrasePattern(
    '$wordStart(?:в|к)\\s+половин[еуа]\\s+(?<h>$ordinalPattern)$_qualifier$wordEnd');

final _clock = phrasePattern('$wordStart(?:(?:в|во|к|на|до|с)\\s+)?'
    '(?<h>\\d{1,2}):(?<m>\\d{2})$_qualifier$wordEnd');

final _oneOClock =
    phrasePattern('$wordStart(?:в|к|до)\\s+часу?(?:\\s+(?<q>дня|ночи))?$wordEnd');

final _hourWithPreposition =
    phrasePattern('$wordStart(?:в|во|к|до)\\s+(?<h>$numberPattern)'
        '(?:\\s+(?:часов|часа|час))?'
        '(?:\\s+(?<m>$numberPattern)\\s+(?:минут|минуты|минуту))?'
        '$_qualifier$wordEnd');

/// «На 12 часов дня», «на 9 утра» — время, только если сказано «часов» или
/// часть суток: «на 2 человек» временем не станет.
final _hourWithNa = phrasePattern('$wordStartна\\s+(?<h>$numberPattern)'
    '(?:\\s+(?:часов|часа|час)(?:\\s+(?<m>$numberPattern)\\s+(?:минут|минуты'
    '|минуту))?(?:\\s+(?<q>утра|дня|вечера|ночи))?'
    '|\\s+(?<q2>утра|дня|вечера|ночи))$wordEnd');

final _hourWithQualifier = phrasePattern('$wordStart(?<h>$numberPattern)'
    '(?:\\s+(?:часов|часа|час))?\\s+(?<q>утра|вечера|ночи)$wordEnd');

// «С днём рождения», «с днём учителя» — праздник, а не время суток.
final _dayPart = phrasePattern('$wordStart(?<p>с\\s+утра|утром|(?<!с\\s)днем'
    '|в\\s+обед|после\\s+обеда|вечером|ночью)$wordEnd');

final _bareTime = phrasePattern('^(?:в\\s+)?(?<h>$numberPattern)'
    '(?:\\s+(?:часов|часа|час))?'
    '(?:\\s+(?<m>$numberPattern)(?:\\s+(?:минут|минуты|минуту))?)?'
    '$_qualifier\$');

final _range = phrasePattern(
    '$wordStart(?:с|со)\\s+(?<h1>\\d{1,2})(?::(?<m1>\\d{2}))?'
    '\\s+до\\s+(?<h2>\\d{1,2})(?::(?<m2>\\d{2}))?'
    '(?:\\s+(?<q>утра|дня|вечера|ночи))?$wordEnd');
final _lengthMinutes = phrasePattern('$wordStart(?:(?:на|около|примерно\\s+на)'
    '\\s+(?<n>$numberPattern)\\s+минут[а-я]*|минут\\s+на\\s+'
    '(?<n2>$numberPattern))$wordEnd');
final _halfHourLength =
    phrasePattern('$wordStartна\\s+(?:полчаса|пол\\s+часа)$wordEnd');
final _hourAndHalfLength =
    phrasePattern('$wordStartна\\s+полтора\\s+часа$wordEnd');
final _hourLength = phrasePattern(
    '$wordStartна\\s+(?:час|часок)$wordEnd(?!\\s+(?:дня|ночи|утра|вечера))');
