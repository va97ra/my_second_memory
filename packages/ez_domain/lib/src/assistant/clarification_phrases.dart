import 'jarvis_command.dart';
import 'jarvis_command_parser.dart';
import 'jarvis_phrase.dart';
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
