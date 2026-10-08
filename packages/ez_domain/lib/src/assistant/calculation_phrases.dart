import '../calculator/calculator_engine.dart';
import 'jarvis_command.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';

/// Устный счёт: «сколько будет 25 на 4», «посчитай 1500 разделить на 3»,
/// «15 процентов от 2000», «корень из 144», «2 в степени 10».
///
/// Фраза переводится на язык калькулятора и считается тем же движком, что
/// и на странице калькулятора: второго счёта в приложении нет.
JarvisCommand? calculationCommand(String work) {
  final trigger = _trigger.firstMatch(work);
  final body = trigger == null ? work : work.substring(trigger.end).trim();
  final expression = spokenExpression(body);
  if (expression == null) return null;
  // Без «сколько будет» фраза должна быть одним выражением: «25 на 4».
  if (trigger == null && !_hasOperator.hasMatch(expression)) return null;
  return Calculate(expression);
}

/// Выражение языком калькулятора или null, если во фразе есть что-то,
/// кроме чисел и действий.
String? spokenExpression(String text) {
  var source = replaceNumberWords(text);
  for (final (pattern, replacement) in _operators) {
    source = source.replaceAllMapped(pattern, replacement);
  }
  source = source.replaceAll(RegExp(r'(?<=\d),(?=\d)'), '.');
  source = source.replaceAll(RegExp(r'\s+'), '');
  if (source.isEmpty || !RegExp(r'^[\d.+\-*/^%()a-z]+$').hasMatch(source)) {
    return null;
  }
  if (!RegExp(r'\d').hasMatch(source)) return null;
  return source;
}

/// Ответ вслух: «25 на 4 — это 100.»
String calculationReply(Calculate command) {
  final result = const CalculatorEngine().evaluate(command.expression);
  final value = result.value;
  if (value == null) return 'Не сумел это посчитать. Скажите выражение иначе.';
  return 'Получается ${spokenNumber(value)}.';
}

/// Число так, как его говорят: запятая вместо точки и не больше шести
/// знаков после неё — треть вслух не читают тридцатью тройками.
String spokenNumber(String value) {
  final dot = value.indexOf('.');
  var shown = value;
  if (dot >= 0 && !value.contains('e') && value.length - dot - 1 > 6) {
    shown = double.parse(value)
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return shown.replaceAll('.', ',');
}

final _trigger = phrasePattern('^(?:сколько\\s+(?:будет|получится)'
    '|посчитай|подсчитай|вычисли|рассчитай|сосчитай|сколько)$wordEnd');

final _hasOperator = RegExp(r'[+\-*/^%]|sqrt');

final _operators = <(RegExp, String Function(Match))>[
  (
    phrasePattern('(?<p>\\d+(?:[.,]\\d+)?)\\s*процент[а-я]*\\s+от\\s+'
        '(?<n>\\d+(?:[.,]\\d+)?)'),
    (m) => '${(m as RegExpMatch).namedGroup('n')}*${m.namedGroup('p')}%'
  ),
  (
    phrasePattern('(?:квадратн[а-я]+\\s+)?корень\\s+(?:квадратный\\s+)?из\\s+'
        '(?<n>\\d+(?:[.,]\\d+)?)'),
    (m) => 'sqrt(${(m as RegExpMatch).namedGroup('n')})'
  ),
  (phrasePattern('\\s*в\\s+квадрате$wordEnd'), (_) => '^2'),
  (phrasePattern('\\s*в\\s+кубе$wordEnd'), (_) => '^3'),
  (phrasePattern('\\s*в\\s+степени\\s+'), (_) => '^'),
  (
    phrasePattern('$wordStart(?:плюс|прибавить|прибавь|сложить\\s+с)$wordEnd'),
    (_) => '+'
  ),
  (
    phrasePattern('$wordStart(?:минус|отнять|вычесть|отними)$wordEnd'),
    (_) => '-'
  ),
  (
    phrasePattern(
        '$wordStart(?:умножить|умножь|помножить|помножь)\\s+на$wordEnd'),
    (_) => '*'
  ),
  (
    phrasePattern('$wordStart(?:разделить|раздели|поделить|подели|делить)'
        '\\s+на$wordEnd'),
    (_) => '/'
  ),
  // «25 на 4» — умножение: так считают вслух.
  (phrasePattern('(?<=\\d)\\s+на\\s+(?=\\d)'), (_) => '*'),
  (phrasePattern('(?<=\\d)\\s*[xх×]\\s*(?=\\d)'), (_) => '*'),
  (phrasePattern('[÷:]'), (_) => '/'),
  (phrasePattern('$wordStartпроцент[а-я]*$wordEnd'), (_) => '%'),
];
