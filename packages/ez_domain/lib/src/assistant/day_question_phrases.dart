import '../language/russian_plural.dart';
import '../recurrence/recurrence_dates.dart';
import 'history_phrases.dart' show monthsPrepositional;
import 'jarvis_command.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';
import 'task_phrase.dart';

/// Вопросы о дне: «я завтра работаю?», «у меня в субботу смена?», «завтра
/// выходной?», «какой сегодня праздник», «что за праздник 4 ноября».
JarvisCommand? dayQuestionCommand(String work, DateTime now) {
  if (_alarm.hasMatch(work) && _asksAlarm.hasMatch(work)) {
    return const AskAlarms();
  }
  if (_holiday.hasMatch(work) && _asksHoliday.hasMatch(work)) {
    return AskHolidays(_dayOf(work, now));
  }
  // «завтра смена в 8» — уже дело со временем, а не вопрос о графике.
  if (_shift.hasMatch(work) &&
      _asksShift.hasMatch(work) &&
      const TaskPhraseParser().parse(work, now).task.minutes == null) {
    return AskShift(_dayOf(work, now),
        findNext: _whenNext.hasMatch(work), dayOff: _dayOff.hasMatch(work));
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
  if (command.findNext && command.dayOff && working.isNotEmpty) {
    return 'Выходного в ближайшие два месяца нет — смены каждый день.';
  }
  if (working.isEmpty) return '$day у вас выходной.';
  if (working.length == 1) return '$day у вас смена: ${working.single}.';
  return '$day у вас смены: ${joinWithAnd(working)}.';
}

/// «В октябре у вас 15 смен.» Часов в графиках нет — так и сказать.
String shiftCountReply(
  AskShiftCount command, {
  required int count,
  required DateTime now,
}) {
  final month = command.month;
  final current = month.year == now.year && month.month == now.month;
  final when = current
      ? (command.pastOnly ? 'С начала месяца' : 'В этом месяце')
      : 'В ${monthsPrepositional[month.month - 1]}';
  final verb = command.pastOnly ? 'отработано' : 'у вас';
  final shifts = count == 0
      ? 'смен нет'
      : '$verb $count ${russianPlural(count, 'смена', 'смены', 'смен')}';
  final days = '$when $shifts.';
  return command.hours
      ? 'Часы в графиках смен не записаны — только дни. $days'
      : days;
}

/// Будильник Ежедневника для ответа: когда и о чём.
typedef AlarmMention = ({DateTime at, String what});

/// Ответ о будильниках: ближайшие по порядку. «Будильников нет» — значит
/// нет ни напоминаний с мелодией, ни будильников графиков.
String alarmsReply(List<AlarmMention> alarms, DateTime now) {
  if (alarms.isEmpty) {
    return 'Будильников в Ежедневнике нет: ни у записей, ни у графиков смен.';
  }
  final sorted = [...alarms]..sort((left, right) => left.at.compareTo(right.at));
  String one(AlarmMention alarm) {
    final when = spokenMoment(
        alarm.at, alarm.at.hour * 60 + alarm.at.minute, now);
    return '$when — ${lowerFirst(alarm.what)}';
  }

  if (sorted.length == 1) return 'Ближайший будильник: ${one(sorted.single)}.';
  const shown = 5;
  final more = sorted.length > shown ? '; и ещё ${sorted.length - shown}' : '';
  return 'Ближайшие будильники: '
      '${sorted.take(shown).map(one).join('; ')}$more.';
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

final _whenNext = phrasePattern('^(?:а\\s+)?когда$wordEnd');
final _dayOff = phrasePattern('$wordStartвыходн[а-я]*$wordEnd');

final _alarm = phrasePattern('$wordStartбудильник[а-я]*$wordEnd');

/// Спрашивают, а не просят поставить: «поставь будильник» — не вопрос.
final _asksAlarm = phrasePattern('^(?:какие|какой|когда|во\\s+сколько|мои'
    '|мой|у\\s+меня|есть\\s+ли|покажи|скажи|подскажи|назови|а|список)$wordEnd'
    '|\\?\$');

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
