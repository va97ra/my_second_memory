import '../recurrence/recurrence_dates.dart';
import 'date_phrases.dart';
import 'jarvis_command.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';
import 'task_phrase.dart';

/// Вопросы о своём расписании: «что у меня завтра», «какие задачи на
/// выходных», «чем я занят в пятницу», «что без даты».
///
/// Ответ строится по календарю, без нейросети: мгновенно и всегда точно.
JarvisCommand? agendaCommand(String work, DateTime now) {
  if (!_question.hasMatch(work) || _notSchedule.hasMatch(work)) return null;
  if (_undated.hasMatch(work)) return const AskUndated();
  final today = dateOnly(now);
  final monday = _addDays(today, 1 - today.weekday);
  if (_nextWeek.hasMatch(work)) {
    return AskAgenda(
      from: _addDays(monday, 7),
      to: _addDays(monday, 13),
      label: 'На следующей неделе',
    );
  }
  if (_week.hasMatch(work)) {
    return AskAgenda(
      from: today,
      to: _addDays(monday, 6),
      label: 'До конца недели',
    );
  }
  if (_weekend.hasMatch(work)) {
    return AskAgenda(
      from: nearestWeekend(today),
      to: _addDays(monday, 6),
      label: 'На выходных',
    );
  }
  final day = const TaskPhraseParser().parseAnswer(work, now).date ?? today;
  return AskAgenda(from: day, to: day, label: spokenDay(day, now));
}

DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

final _question = phrasePattern('$wordStart(?:что\\s+у\\s+меня'
    '|что\\s+мне\\s+(?:надо|нужно)|чем\\s+я[^?.!]*занят[а-я]*'
    '|мои\\s+(?:дела|планы|задачи|встречи)'
    '|что\\s+(?:мне\\s+)?(?:делать|сделать)\\s+(?:сегодня|завтра|послезавтра)$wordEnd'
    '|что[- ]нибудь[^?.!]*(?:сегодня|завтра|послезавтра)$wordEnd'
    '|как[а-я]*[^?.!]*$wordStart(?:дела|планы|задачи|встречи)$wordEnd'
    '|что[^?.!]*$wordStart(?:запланирован[а-я]*|по\\s+делам|по\\s+задачам'
    '|надо\\s+сделать|нужно\\s+сделать)'
    '|что\\s+на\\s+(?:сегодня|завтра|послезавтра)$wordEnd'
    '|(?:дела|планы|задачи|расписание)\\s+на|расписани[а-я]*'
    '|сколько[^?.!]*$wordStart(?:дел|задач|встреч)$wordEnd'
    '|есть\\s+ли[^?.!]*$wordStart(?:дела|планы|задачи|встречи)$wordEnd'
    '|(?:покажи|расскажи|напомни)\\s+(?:мне\\s+)?(?:дела|планы|задачи'
    '|расписание))');

/// Похоже на вопрос о расписании, но это правка, деньги или настройки.
final _notSchedule = phrasePattern('$wordStart(?:перенеси|перенести|удали'
    '|убери|отметь|запомни|потратил[а-я]*|заработал[а-я]*|курс[а-я]*'
    '|смен[а-я]*|праздник[а-я]*)$wordEnd');

final _undated = phrasePattern('без\\s+(?:даты|дня|срока)');
final _nextWeek = phrasePattern('следующ[а-я]*\\s+недел');
final _week = phrasePattern('недел');
final _weekend = phrasePattern('выходн');
