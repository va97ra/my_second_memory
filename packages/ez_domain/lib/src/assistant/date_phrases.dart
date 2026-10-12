import '../recurrence/recurrence_dates.dart';
import 'moment_hits.dart';
import 'phrase_scan.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';

/// Вынимает из фразы дни: «завтра», «через неделю», «15 октября», «15.10»,
/// «20 числа», «в следующий вторник», «на выходных».
void collectDates(PhraseScan scan, MomentHits hits, DateTime now) {
  final today = dateOnly(now);

  for (final match in scan.take(_relativeDays)) {
    final raw = match.namedGroup('n');
    final count = raw == null ? 1 : numberFromWords(raw);
    if (count == null) continue;
    final unit = match.namedGroup('u')!;
    hits.dates.add(switch (unit) {
      _ when unit.startsWith('нед') => _addDays(today, 7 * count),
      _ when unit.startsWith('месяц') => _addMonths(today, count),
      _ when unit.startsWith('год') || unit == 'лет' =>
        _addMonths(today, 12 * count),
      _ => _addDays(today, count),
    });
  }

  for (final match in scan.take(_numericDate)) {
    final rawYear = match.namedGroup('y');
    var year = rawYear == null ? null : int.parse(rawYear);
    if (year != null && year < 100) year += 2000;
    final date = _makeDate(
      int.parse(match.namedGroup('d')!),
      int.parse(match.namedGroup('mo')!),
      year,
      today,
    );
    if (date != null) hits.dates.add(date);
  }

  for (final match in scan.take(_monthDate)) {
    final raw = match.namedGroup('d')!;
    final day = numberFromWords(raw) ?? ordinalFromWords(raw);
    if (day == null) continue;
    final month = monthFromGenitive(match.namedGroup('mo')!);
    final date = _makeDate(day, month, null, today);
    if (date != null) hits.dates.add(date);
  }

  for (final match in scan.take(_dayOfMonth)) {
    final raw = match.namedGroup('d') ??
        match.namedGroup('d2') ??
        match.namedGroup('d3')!;
    final day = numberFromWords(raw) ?? ordinalFromWords(raw);
    if (day == null || day < 1 || day > 31) continue;
    var date = _makeDate(day, today.month, today.year, today, rollYear: false);
    if (date == null || date.isBefore(today)) {
      final next = DateTime(today.year, today.month + 1);
      date = _makeDate(day, next.month, next.year, today, rollYear: false);
    }
    if (date != null) hits.dates.add(date);
  }

  for (final match in scan.take(_dayWord)) {
    hits.dates.add(switch (match.namedGroup('w')!) {
      'сегодня' => today,
      'завтра' => _addDays(today, 1),
      'послезавтра' => _addDays(today, 2),
      'вчера' => _addDays(today, -1),
      'позавчера' => _addDays(today, -2),
      _ => nearestWeekend(today),
    });
  }

  // «на следующей неделе» уточняет день недели, а без него дата неясна.
  String? weekModifier;
  for (final match in scan.take(_weekPhrase)) {
    weekModifier = match.namedGroup('w');
  }
  final weekdays = scan.take(_weekday);
  if (weekdays.isEmpty && weekModifier != null) hits.vagueDate = true;
  for (final match in weekdays) {
    final target = weekdayFromWord(match.namedGroup('d')!);
    final modifier = match.namedGroup('mod') ?? weekModifier;
    hits.dates.add(_weekdayDate(today, target, modifier));
  }
}

/// Суббота этих выходных; в субботу и воскресенье — сегодня.
DateTime nearestWeekend(DateTime today) => today.weekday >= DateTime.saturday
    ? today
    : _addDays(today, DateTime.saturday - today.weekday);

DateTime _weekdayDate(DateTime today, int target, String? modifier) {
  final weekday = today.weekday;
  if (modifier != null && modifier.startsWith('следующ')) {
    return _addDays(today, 7 - (weekday - 1) + (target - 1));
  }
  if (modifier != null && modifier.startsWith('эт')) {
    final date = _addDays(today, target - weekday);
    return date.isBefore(today) ? _addDays(date, 7) : date;
  }
  // Сегодняшний день недели — это следующий такой день, а не сегодня:
  // «в пятницу», сказанное в пятницу, значит через неделю.
  final delta = (target - weekday + 7) % 7;
  return _addDays(today, delta == 0 ? 7 : delta);
}

DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

DateTime _addMonths(DateTime date, int months) =>
    safeDate(date.year, date.month + months, date.day);

/// День по числу и месяцу. Без года — ближайший такой день: «15 марта»,
/// сказанное в октябре, — это март следующего года.
DateTime? _makeDate(
  int day,
  int month,
  int? year,
  DateTime today, {
  bool rollYear = true,
}) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final resolvedYear = year ?? today.year;
  var date = DateTime(resolvedYear, month, day);
  if (date.month != month || date.day != day) return null;
  if (year == null && rollYear && date.isBefore(today)) {
    date = DateTime(resolvedYear + 1, month, day);
    if (date.month != month) return null;
  }
  return date;
}

final _relativeDays = phrasePattern('$wordStart(?:через|спустя)\\s+'
    '(?:(?<n>$numberPattern|пару)\\s+)?'
    '(?<u>день|дня|дней|сутки|суток|неделю|недели|недель|месяц|месяца|месяцев'
    '|год|года|лет)$wordEnd');

final _numericDate = phrasePattern('$wordStart(?:(?:на|к|до)\\s+)?'
    r'(?<d>\d{1,2})\.(?<mo>\d{1,2})(?:\.(?<y>\d{4}|\d{2}))?'
    '$wordEnd');

final _monthDate = phrasePattern('$wordStart(?:(?:на|к|до)\\s+)?'
    '(?<d>$ordinalDayPattern|$numberPattern)(?:\\s*-?\\s*(?:го|е|ое|му))?'
    '\\s+(?<mo>$monthsGenitivePattern)$wordEnd');

/// Число этого месяца: «12 числа», «на 12 число», «к 12 числу», «12-го»,
/// «на 12-е», «на двенадцатое». Порядковое без «числа» — только с
/// предлогом и не перед блюдом: «на второе» бывает и котлетами.
final _dayOfMonth = phrasePattern('$wordStart(?:(?:на|к|до)\\s+)?'
    '(?:(?<d>$ordinalDayPattern|$numberPattern)(?:\\s*-?\\s*(?:го|е|ое|му))?'
    '\\s+числ(?:а|о|у|ом)'
    '|(?<d2>\\d{1,2})\\s*-\\s*(?:го|е|ое|му))$wordEnd'
    '|$wordStart(?:на|к|до)\\s+(?<d3>$ordinalDayPattern)$wordEnd'
    '(?!\\s+блюд)');

final _dayWord = phrasePattern('$wordStart(?:(?:на|к|до|в)\\s+)?'
    '(?:(?:эти|этих|ближайшие|ближайших)\\s+)?'
    '(?<w>послезавтра|позавчера|завтра|вчера|сегодня|выходных|выходные)'
    '$wordEnd');

final _weekPhrase = phrasePattern(
    '$wordStart(?:на\\s+)?(?<w>следующей|этой)\\s+неделе$wordEnd');

final _weekday = phrasePattern('$wordStart(?:(?:в|во|на|к|до)\\s+)?'
    '(?:(?<mod>следующ(?:ий|ую|ее|ей|его|ему)|эт(?:от|у|о|ой|ого|ому))\\s+)?'
    '(?<d>понедельник[ау]?|вторник[ау]?|сред[аеуы]|четверг[ау]?|пятниц[аеуы]'
    '|суббот[аеуы]|воскресень[еяю])$wordEnd');
