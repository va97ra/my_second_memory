import '../recurrence/recurrence_dates.dart';
import 'jarvis_command.dart';
import 'russian_words.dart';
import 'task_phrase.dart';

/// Вопросы о дне: «я завтра работаю?», «у меня в субботу смена?», «завтра
/// выходной?», «какой сегодня праздник», «что за праздник 4 ноября».
JarvisCommand? dayQuestionCommand(String work, DateTime now) {
  if (_holiday.hasMatch(work) && _asksHoliday.hasMatch(work)) {
    return AskHolidays(_dayOf(work, now));
  }
  // «завтра смена в 8» — уже дело со временем, а не вопрос о графике.
  if (_shift.hasMatch(work) &&
      _asksShift.hasMatch(work) &&
      const TaskPhraseParser().parse(work, now).task.minutes == null) {
    return AskShift(_dayOf(work, now), findNext: _whenNext.hasMatch(work));
  }
  return null;
}

/// Ответ о смене. [working] — названия графиков, по которым день рабочий.
String shiftReply(
  AskShift command, {
  required List<String> working,
  required bool hasSchedules,
  required String dayLabel,
}) {
  if (!hasSchedules) {
    return 'Графиков смен у вас нет. Их можно завести в настройках.';
  }
  final day = capitalizeFirst(dayLabel);
  if (working.isEmpty) return '$day у вас выходной.';
  if (working.length == 1) return '$day у вас смена: ${working.single}.';
  return '$day у вас смены: ${joinWithAnd(working)}.';
}

/// Ответ о праздниках дня.
String holidaysReply({required List<String> titles, required String dayLabel}) {
  final day = capitalizeFirst(dayLabel);
  if (titles.isEmpty) return '$day праздников нет.';
  if (titles.length == 1) return '$day — ${titles.single}.';
  return '$day: ${joinWithAnd(titles)}.';
}

DateTime _dayOf(String work, DateTime now) =>
    const TaskPhraseParser().parseAnswer(work, now).date ?? dateOnly(now);

final _whenNext = phrasePattern('^когда$wordEnd');

final _holiday = phrasePattern('$wordStartпраздник[а-я]*$wordEnd');

final _asksHoliday = phrasePattern('^(?:какой|какие|что\\s+за|есть\\s+ли'
    '|а\\s+какой|скажи|подскажи|расскажи\\s+про)$wordEnd'
    '|$wordStart(?:сегодня|завтра|послезавтра)\\s+праздник'
    '|праздник[а-я]*\\s+(?:сегодня|завтра|послезавтра)|\\?\$');

final _shift = phrasePattern('$wordStart(?:работаю|смена|смены|смене'
    '|выходной|выходная|рабочий\\s+день)$wordEnd');

final _asksShift = phrasePattern('^(?:я|у\\s+меня|мне|когда|работаю|завтра'
    '|сегодня|послезавтра|в\\s+[а-я]+|а|скажи|подскажи|есть\\s+ли|ли)$wordEnd'
    '|$wordStartли$wordEnd|\\?\$');
