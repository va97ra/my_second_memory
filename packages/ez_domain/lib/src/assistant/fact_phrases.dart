import 'jarvis_command.dart';
import 'jarvis_phrase.dart';
import 'russian_words.dart';
import 'task_phrase.dart';

/// Память Джарвиса о хозяине: «запомни, что мама любит белые розы», «я живу
/// в Казани» — и потом «что любит мама?».
///
/// Дело на потом сюда не попадает: «запомни, что завтра врач» — запись в
/// календаре, «запомни купить хлеб» — записка. Пароли, коды и PIN не
/// запоминаются: отказ узнаётся раньше (`refusalCommand`).
JarvisCommand? factCommand(JarvisPhrase phrase, DateTime now) {
  final work = phrase.work;
  if (_list.hasMatch(work)) return const ListFacts();
  final forget = _forget.firstMatch(work);
  if (forget != null) {
    return ForgetFact(_tail(phrase, forget.namedGroup('t')!));
  }
  final remember = _remember.firstMatch(work);
  if (remember == null) return null;
  final said = remember.namedGroup('t')!;
  if (_doing.hasMatch(said)) return null;
  final task = const TaskPhraseParser().parse(said, now).task;
  if (task.date != null || task.minutes != null) return null;
  return RememberFact(capitalizeFirst(_tail(phrase, said)));
}

/// Самое подходящее к вопросу из того, что Джарвис помнит; null — ничего
/// подходящего. Сравниваются основы слов без служебных: «что любит мама?»
/// находит «Мама любит белые розы».
String? factFor(String question, List<String> facts) {
  final asked = _meaningful(question);
  if (asked.isEmpty) return null;
  String? best;
  var bestScore = 0;
  for (final fact in facts) {
    final known = _meaningful(fact).toSet();
    final score = asked.where(known.contains).length;
    if (score > bestScore) {
      best = fact;
      bestScore = score;
    }
  }
  return best;
}

/// Ответы о памяти.
abstract final class FactReplies {
  static String remembered(String fact) => 'Запомнил: ${_inside(fact)}.';

  static String forgotten(String fact) => 'Забыл: ${_inside(fact)}.';

  static const unknown = 'Такого я не помню.';

  static String list(List<String> facts) => facts.isEmpty
      ? 'Пока я ничего о вас не запомнил. Скажите: «запомни, что …».'
      : 'Я помню: ${facts.map(_inside).join('; ')}.';

  static String answer(String fact) => 'Вы говорили: ${_inside(fact)}.';

  /// Посреди фразы: «я живу в Казани» — «я» строчная, хотя одна буква.
  static String _inside(String fact) =>
      fact.startsWith('Я ') ? 'я${fact.substring(1)}' : lowerFirst(fact);
}

/// Конец фразы с исходными буквами: разбор не меняет длину фразы.
String _tail(JarvisPhrase phrase, String said) {
  return phrase.text
      .substring(phrase.text.length - said.length)
      .replaceFirst(RegExp(r'[\s.!]+$'), '')
      .trim();
}

List<String> _meaningful(String text) => [
      for (final stem in searchStems(text))
        if (!_service.contains(stem)) stem,
    ];

/// Слова вопроса, по которым факт не найти.
const _service = {
  'что', 'кто', 'где', 'как', 'какой', 'какая', 'какое', 'какие', 'когда',
  'мне', 'меня', 'мой', 'моя', 'мое', 'мои', 'моего', 'моей', 'моих', 'у',
  'в', 'на', 'по', 'это', 'ты', 'тебе', 'знаешь', 'помнишь', 'скажи',
  'напомни', 'я', 'же', 'ли', 'а', 'и', 'про', 'о', 'об', 'за',
};

final _remember = phrasePattern(
    '^(?:запомни|запомните|учти|имей\\s+в\\s+виду)[\\s,:]+(?:что[\\s,]+)?(?<t>.+)\$');

final _forget = phrasePattern(
    '^(?:забудь|забудьте)[\\s,:]+(?:что[\\s,]+|про\\s+|о\\s+)?(?<t>.+)\$');

final _list = phrasePattern('^(?:что\\s+ты\\s+(?:обо\\s+мне\\s+)?(?:знаешь'
    '|помнишь)(?:\\s+обо\\s+мне)?|что\\s+ты\\s+запомнил)\$');

/// Дело начинается с действия: «купить хлеб» — записка, а не память.
final _doing = phrasePattern('^[а-я]+(?:ть|ти|ться|тись)$wordEnd');
