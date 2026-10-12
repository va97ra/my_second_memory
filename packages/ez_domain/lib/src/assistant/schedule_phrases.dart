import '../recurrence/recurrence_dates.dart';
import 'history_phrases.dart' show monthsPrepositional;
import 'jarvis_command.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';
import 'task_phrase.dart';

/// Вопросы о времени и работе: «что у меня дальше», «когда я свободен на
/// неделе», «есть окно в пятницу», «сколько смен в этом месяце», «сколько
/// часов отработал».
JarvisCommand? scheduleCommand(String work, DateTime now) {
  if (_next.hasMatch(work)) return const AskNext();
  if (_free.hasMatch(work) && _asks.hasMatch(work)) return _freeOf(work, now);
  if (_shiftCount.hasMatch(work)) {
    return AskShiftCount(
      _monthOf(work, now),
      hours: _hours.hasMatch(work),
      pastOnly: _worked.hasMatch(work),
    );
  }
  return null;
}

AskFree _freeOf(String work, DateTime now) {
  final today = dateOnly(now);
  final monday = _addDays(today, 1 - today.weekday);
  if (_nextWeek.hasMatch(work)) {
    return AskFree(
        from: _addDays(monday, 7),
        to: _addDays(monday, 13),
        label: 'на следующей неделе');
  }
  if (_weekend.hasMatch(work)) {
    final saturday = _addDays(monday, 5);
    return AskFree(
        from: saturday.isBefore(today) ? today : saturday,
        to: _addDays(monday, 6),
        label: 'на выходных');
  }
  if (_week.hasMatch(work)) {
    return AskFree(from: today, to: _addDays(monday, 6), label: 'на неделе');
  }
  final day = const TaskPhraseParser().parseAnswer(work, now).date;
  if (day != null) {
    return AskFree(from: day, to: day, label: spokenDay(day, now));
  }
  // «Когда я свободен» без срока — ближайшая неделя.
  return AskFree(
      from: today, to: _addDays(today, 6), label: 'в ближайшую неделю');
}

DateTime _monthOf(String work, DateTime now) {
  if (_lastMonth.hasMatch(work)) return DateTime(now.year, now.month - 1);
  if (_nextMonth.hasMatch(work)) return DateTime(now.year, now.month + 1);
  for (var i = 0; i < 12; i++) {
    final named = phrasePattern('$wordStart(?:${monthsPrepositional[i]}'
        '|${monthsNominative[i]})$wordEnd');
    if (named.hasMatch(work)) return DateTime(now.year, i + 1);
  }
  return DateTime(now.year, now.month);
}

DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

final _next = phrasePattern('^(?:а\\s+)?(?:что\\s+(?:у\\s+меня\\s+)?'
    '(?:дальше|следующее|потом|после\\s+этого)(?:\\s+по\\s+плану)?'
    '|(?:как[а-я]+\\s+)?следующ[а-я]*\\s+(?:дело|задача|встреча|запись'
    '|по\\s+плану)|куда\\s+(?:мне\\s+)?(?:дальше|потом))'
    '(?:\\s+(?:у\\s+меня|сегодня))?\$');

final _free = phrasePattern('$wordStart(?:свобод[а-я]*|окн[оа]|окошк[оа]'
    '|не\\s+занят[а-я]*)$wordEnd');

final _asks = phrasePattern('^(?:а\\s+)?(?:когда|есть|какой|какие|в\\s+какой'
    '|в\\s+какие|у\\s+меня|я|найди|подскажи|скажи|будет)$wordEnd');

final _shiftCount = phrasePattern('^(?:а\\s+)?сколько\\s+(?:у\\s+меня\\s+)?'
    '(?:(?:я\\s+)?(?:смен|рабочих\\s+дней|часов)|я\\s+(?:отработал[а-я]*'
    '|работал[а-я]*|работаю))$wordEnd');
final _hours = phrasePattern('$wordStartчасов$wordEnd');
final _worked = phrasePattern('$wordStart(?:отработал[а-я]*|работал[а-я]*)'
    '$wordEnd');

final _lastMonth = phrasePattern('прошл[а-я]*\\s+месяц');
final _nextMonth = phrasePattern('следующ[а-я]*\\s+месяц');
final _nextWeek = phrasePattern('следующ[а-я]*\\s+недел');
final _week = phrasePattern('недел');
final _weekend = phrasePattern('выходн');
