import 'jarvis_command.dart';
import 'phrase_moments.dart';
import 'phrase_scan.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';

/// Открыть страницу: «открой календарь», «покажи записки», «калькулятор»,
/// «покажи завтра», «открой 15 октября», «покажи ноябрь».
///
/// Страница узнаётся по слову, а не по месту в фразе. Глагол нужен, только
/// когда кроме страницы во фразе что-то есть: одно слово «календарь» — это
/// тоже просьба его открыть.
JarvisCommand? placeCommand(String work, DateTime now) {
  final verb = _verb.firstMatch(work);
  final rest = verb == null ? work : work.substring(verb.end).trim();
  if (rest.isEmpty) return null;

  for (final (pattern, place) in _places) {
    final match = pattern.firstMatch(rest);
    if (match == null) continue;
    final leftover = rest
        .replaceRange(match.start, match.end, ' ')
        .replaceAll(_filler, ' ')
        .trim();
    if (leftover.isEmpty) return OpenPlace(place);
    // Без глагола страница должна быть всей фразой: «финансы за сентябрь» —
    // ещё может быть вопросом, а «финансы» — уже просьба.
    if (verb == null) return null;
    final date = _monthIn(leftover, now) ?? _onlyDate(leftover, now);
    // «покажи записки про врача» — это уже поиск, а не страница.
    return date == null ? null : OpenPlace(place, date: date);
  }

  // «покажи завтра», «открой 15 октября» — день календаря.
  if (verb == null) return null;
  final month = _monthIn(rest, now);
  if (month != null) return OpenPlace(JarvisPlace.calendar, date: month);
  final day = _onlyDate(rest, now);
  if (day != null) return OpenPlace(JarvisPlace.day, date: day);
  return null;
}

/// «Посмотри на календарь», «что в финансах», «загляни в записки», «что
/// здесь», «прочитай» — Джарвис смотрит на страницу и рассказывает, что на
/// ней. Страницы узнаются теми же словами, что и в «открой …».
JarvisCommand? lookCommand(String work, DateTime now) {
  if (_here.hasMatch(work)) return const LookAtPage();
  final verb = _look.firstMatch(work);
  if (verb == null) return null;
  final rest = work.substring(verb.end).replaceAll(_filler, ' ').trim();
  if (rest.isEmpty) return const LookAtPage();
  for (final (pattern, place) in _places) {
    final match = pattern.firstMatch(rest);
    if (match == null) continue;
    final leftover = rest.replaceRange(match.start, match.end, ' ').trim();
    if (leftover.isEmpty) return LookAtPage(place: place);
    final date = _onlyDate(leftover, now);
    if (date == null) return null;
    // «Посмотри календарь на пятницу» — это день, а не месяц.
    final day = place == JarvisPlace.calendar ? JarvisPlace.day : place;
    return LookAtPage(place: day, date: date);
  }
  return null;
}

/// «Что здесь», «прочитай» — о той странице, что на экране.
final _here = phrasePattern('^(?:что\\s+(?:(?:здесь|тут)(?:\\s+(?:написано'
    '|есть))?|на\\s+(?:экране|этой\\s+странице)|ты\\s+(?:тут\\s+|здесь\\s+)?'
    'видишь)|(?:прочитай|прочти|почитай)(?:\\s+(?:это|что\\s+(?:здесь|тут)))?'
    '|расскажи\\s+что\\s+(?:здесь|тут))\$');

/// «Посмотри на …», «загляни в …», «что в …».
final _look = phrasePattern('^(?:(?:посмотри|посмотрите|глянь|гляни|загляни'
    '|взгляни|почитай|прочитай|прочти)(?:\\s+(?:на|в|во))?|что\\s+(?:в|во|на))'
    '$wordEnd');

/// День, если фраза — только он: «завтра», «в пятницу», «15 октября».
DateTime? _onlyDate(String text, DateTime now) {
  final scan = PhraseScan(text);
  final hits = collectMoments(scan, now);
  if (hits.dates.length != 1 || hits.times.isNotEmpty) return null;
  final leftover = scan.work.replaceAll(_dayNoun, '').trim();
  return leftover.isEmpty ? hits.dates.single : null;
}

/// «ноябрь», «на ноябрь», «за ноябрь» — первый день ближайшего такого месяца.
DateTime? _monthIn(String text, DateTime now) {
  final match = _month.firstMatch(text);
  if (match == null) return null;
  final month = monthsNominative.indexOf(match.namedGroup('m')!) + 1;
  final year = month < now.month ? now.year + 1 : now.year;
  final rawYear = match.namedGroup('y');
  return DateTime(rawYear == null ? year : int.parse(rawYear), month);
}

final _verb = phrasePattern('^(?:открой|откройте|открыть|покажи|покажите'
    '|показать|перейди|перейти|зайди|зайти|переключись|вернись|отобрази'
    '|выведи|хочу|давай|запусти|включи)(?:\\s+(?:мне|на|в|во))*$wordEnd');

final _dayNoun =
    phrasePattern('$wordStart(?:день|дату|число|страницу)$wordEnd');

/// Слова, которые ничего не добавляют к названию страницы.
final _filler = phrasePattern('$wordStart(?:мне|пожалуйста|страниц[аеуы]'
    '|раздел|вкладк[аеуы]|экран|окно|мой|мои|мою|все|всё|список)$wordEnd');

final _month = phrasePattern('^(?:(?:на|за|в)\\s+)?'
    '(?<m>${monthsNominative.join('|')})(?:\\s+(?<y>\\d{4}))?(?:\\s+года?)?\$');

RegExp _word(String stems) => phrasePattern('$wordStart(?:$stems)$wordEnd');

/// Страницы и слова, которыми их называют. Порядок важен: «производственный
/// календарь» должен найтись раньше «календаря».
final _places = <(RegExp, JarvisPlace)>[
  (
    _word('производственн[а-я]*\\s+календар[а-я]*'),
    JarvisPlace.productionCalendar
  ),
  (_word('праздник[а-я]*'), JarvisPlace.holidays),
  (_word('календар[а-я]*|месяц'), JarvisPlace.calendar),
  (_word('лент[а-я]*'), JarvisPlace.feed),
  (_word('записк[а-я]*|заметк[а-я]*'), JarvisPlace.notes),
  (_word('архив[а-я]*'), JarvisPlace.archive),
  (_word('аккаунт[а-я]*|учетн[а-я]*\\s+запис[а-я]*'), JarvisPlace.accounts),
  (_word('калькулятор[а-я]*'), JarvisPlace.calculator),
  (
    _word('финанс[а-я]*|бюджет[а-я]*|деньги|кошел[а-я]*|расходы|доходы'),
    JarvisPlace.finance
  ),
  (
    _word('конвертер[а-я]*|перевод\\s+величин|величин[а-я]*'),
    JarvisPlace.converter
  ),
  (_word('график[а-я]*(?:\\s+смен)?|смен[аы]?'), JarvisPlace.shifts),
  (_word('настройк[а-я]*|параметр[а-я]*'), JarvisPlace.settings),
  (
    _word('резервн[а-я]*\\s+копи[а-я]*|бэкап[а-я]*|копи[а-я]*'),
    JarvisPlace.backup
  ),
  (_word('синхронизаци[а-я]*|облак[а-я]*'), JarvisPlace.sync),
];
