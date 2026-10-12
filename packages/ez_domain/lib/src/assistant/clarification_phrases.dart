import 'address_phrases.dart';
import 'jarvis_command.dart';
import 'jarvis_command_parser.dart';
import 'jarvis_phrase.dart';
import 'phone_phrases.dart' show durationSeconds;
import 'russian_words.dart';
import 'task_phrase.dart';

/// Ответ на уточняющий вопрос Джарвиса («во сколько?», «на какой день?»).
sealed class Clarification {
  const Clarification();
}

/// «Не надо», «отмена» — дело не записывать.
final class ClarificationCancel extends Clarification {
  const ClarificationCancel();
}

/// Ответ по делу: день, время, «весь день», «без даты».
final class ClarificationAnswer extends Clarification {
  const ClarificationAnswer(this.answer);

  final TaskAnswer answer;
}

/// Не ответ, а новая просьба: «какие у меня дела на завтра», «открой
/// календарь». Начатое дело записывается как есть, а просьба выполняется.
final class ClarificationNewRequest extends Clarification {
  const ClarificationNewRequest();
}

/// Ответ на вопрос подробной карточки — дело уже с ним; пропуск тоже
/// ответ: о пропущенном второй раз не спрашивают.
final class ClarificationDetail extends Clarification {
  const ClarificationDetail(this.task);

  final ParsedTask task;
}

/// Ответ на вопрос карточки [need] о деле [task]: «полчаса», «никуда»,
/// «взять паспорт», «да, срочно», «не важно».
Clarification readDetail(
  ParsedTask task,
  TaskNeed need,
  String raw,
  DateTime now,
) {
  final phrase = JarvisPhrase(raw);
  final work = phrase.work;
  // На «Это срочно?» «нет» — «не срочно», а не «не записывай».
  if (need == TaskNeed.urgency) {
    if (_yes.hasMatch(work)) {
      return ClarificationDetail(task.copyWith(urgent: true, asked: need));
    }
    if (_no.hasMatch(work)) {
      return ClarificationDetail(task.copyWith(asked: need));
    }
  }
  if (_cancel.hasMatch(work)) return const ClarificationCancel();
  if (_skip.hasMatch(work)) {
    return ClarificationDetail(task.copyWith(asked: need));
  }
  switch (need) {
    case TaskNeed.urgency:
      return const ClarificationNewRequest();
    case TaskNeed.duration:
      final minutes = _lengthOf(task, phrase.text, now);
      if (minutes != null) {
        return ClarificationDetail(
            task.copyWith(durationMinutes: minutes, asked: need));
      }
      return const ClarificationNewRequest();
    case TaskNeed.place:
    case TaskNeed.details:
      if (_isOwnCommand(raw, now)) return const ClarificationNewRequest();
      final text = capitalizeFirst(compactPhrase(phrase.text));
      if (text.isEmpty) return const ClarificationNewRequest();
      return ClarificationDetail(need == TaskNeed.place
          ? task.copyWith(address: addressIn(text) ?? text, asked: need)
          : task.copyWith(details: text, asked: need));
    case TaskNeed.date:
    case TaskNeed.time:
      return readClarification(raw, now, forDate: task.date);
  }
}

/// «Полчаса», «20 минут», «час», «до часу дня» — сколько займёт.
int? _lengthOf(ParsedTask task, String text, DateTime now) {
  final seconds = durationSeconds(text);
  if (seconds != null) return (seconds / 60).ceil();
  final start = task.minutes;
  final end = const TaskPhraseParser()
      .parseAnswer(text, now, forDate: task.date)
      .minutes;
  if (start == null || end == null) return null;
  final length = end - start;
  return length > 0 ? length : null;
}

bool _isOwnCommand(String raw, DateTime now) {
  final command = const JarvisCommandParser().parse(raw, now);
  return command != null &&
      command is! CreateTasks &&
      command is! CreateNote &&
      command is! AskBrain &&
      command is! JarvisSay;
}

/// Что человек сказал в ответ на вопрос о деле на [forDate].
///
/// В новой просьбе тоже бывает «завтра»: «какие дела на завтра» — не ответ
/// «завтра», иначе вопрос повторялся бы по кругу. Поэтому сначала
/// проверяется, не узнаётся ли фраза как своя команда.
Clarification readClarification(
  String raw,
  DateTime now, {
  DateTime? forDate,
}) {
  final phrase = JarvisPhrase(raw);
  if (_cancel.hasMatch(phrase.work)) return const ClarificationCancel();
  final command = const JarvisCommandParser().parse(raw, now);
  final isOwnCommand = command != null &&
      command is! CreateTasks &&
      command is! AskBrain &&
      command is! JarvisSay;
  if (isOwnCommand) return const ClarificationNewRequest();
  final answer =
      const TaskPhraseParser().parseAnswer(phrase.text, now, forDate: forDate);
  if (answer.isEmpty) return const ClarificationNewRequest();
  return ClarificationAnswer(answer);
}

// «Нет» отменяет только само по себе: «нет, в 10» — это ответ.
final _cancel = phrasePattern('^(?:не\\s+надо|не\\s+нужно|не\\s+записывай'
    '|не\\s+запоминай|отмена|отмени|отменить|забудь|стоп|ничего\\s+не\\s+надо)'
    '$wordEnd|^нет\$');

/// Пропустить вопрос карточки: «не важно», «дальше», «никуда», «ничего».
final _skip = phrasePattern('^(?:не\\s+важно|неважно|дальше|пропусти|пропустить'
    '|следующий|никуда|нигде|дома|не\\s+надо\\s+ехать|ничего|не\\s+знаю'
    '|без\\s+разницы|все\\s+равно)$wordEnd');

final _yes = phrasePattern('^(?:да|срочно|важно|очень|конечно|ага|угу'
    '|обязательно)$wordEnd');

final _no = phrasePattern('^(?:нет|не\\s+срочно|не\\s+очень|обычно|не\\s+горит'
    '|не\\s+спешно)$wordEnd');
