import 'jarvis_command.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';

/// Устный счёт: «сколько будет 25 на 4», «посчитай 1500 разделить на 3»,
/// «15 процентов от 2000», «корень из 144», «2 в степени 10».
///
/// Фраза переводится на язык калькулятора, а считает сам калькулятор
/// Ежедневника: Джарвис нажимает его клавиши и читает ответ. Второго счёта
/// в приложении нет (решение владельца 12 октября 2026).
///
/// Фраза, которая начинается с действия, — «прибавь 10», «а теперь умножь
/// на 3», — продолжает то, что уже на калькуляторе.
JarvisCommand? calculationCommand(String work) {
  final asked = work.replaceAll(_onCalculator, ' ').trim();
  final trigger = _trigger.firstMatch(asked);
  if (trigger == null) {
    final tail = _chainTail(asked);
    if (tail != null) {
      return CalculatorCommand(CalculatorMove.chain, tail: tail);
    }
  }
  final body = trigger == null ? asked : asked.substring(trigger.end).trim();
  final expression = spokenExpression(body);
  if (expression == null) return null;
  // Без «сколько будет» фраза должна быть одним выражением: «25 на 4».
  if (trigger == null && !_hasOperator.hasMatch(expression)) return null;
  return Calculate(expression);
}

/// Память, сброс, режимы и «сколько получилось» — действия калькулятором
/// без счёта. Узнаются раньше «запомни»: «сохрани в память» — не о хозяине.
JarvisCommand? calculatorCommand(String work) {
  for (final (pattern, move) in _moves) {
    if (pattern.hasMatch(work)) return CalculatorCommand(move);
  }
  return null;
}

/// Что сделать с тем, что на калькуляторе, или null, если фраза — не
/// продолжение.
String? _chainTail(String work) {
  final body = work.replaceFirst(_chainLead, '').trim();
  for (final (pattern, tail) in _chainWords) {
    if (pattern.hasMatch(body)) return tail;
  }
  final expression = spokenExpression(body);
  if (expression == null || !_leadingAction.hasMatch(expression)) return null;
  return expression;
}

/// Выражение языком калькулятора или null, если во фразе есть что-то,
/// кроме чисел и действий.
String? spokenExpression(String text) {
  var source = replaceNumberWords(text).replaceFirst(_askedAfter, '').trim();
  // «Сложи 200 и 150», «вычти 50 из 200» — действие называют до чисел.
  for (final (pattern, shape) in _namedActions) {
    final match = pattern.firstMatch(source);
    if (match != null) {
      source = shape(match.group(1)!, match.group(2)!);
      break;
    }
  }
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

/// Ответ вслух тем, что показал калькулятор. Простое действие называется
/// целиком — «200 плюс 150 — будет 350», остальное — «Получается 1024».
/// [asked] — что посчитано, языком калькулятора.
String calculationReply(String? value, {String? asked}) {
  if (value == null) return 'Не сумел это посчитать. Скажите выражение иначе.';
  final simple = asked == null ? null : _simpleAction.firstMatch(asked);
  if (simple == null) return 'Получается ${spokenNumber(value)}.';
  final left = spokenNumber(simple.group(1)!);
  final right = spokenNumber(simple.group(3)!);
  return '$left ${_actionWords[simple.group(2)]} $right — будет '
      '${spokenNumber(value)}.';
}

/// «200+150» — два числа и одно действие.
final _simpleAction = RegExp(r'^(-?\d+(?:\.\d+)?)([+\-*/])(\d+(?:\.\d+)?)$');

const _actionWords = {
  '+': 'плюс',
  '-': 'минус',
  '*': 'умножить на',
  '/': 'разделить на',
};

/// Ответ на действие калькулятором. [value] — что на нём сейчас,
/// [memory] — что в памяти, [empty] — на калькуляторе ничего нет.
String calculatorReply(
  CalculatorMove move, {
  String? value,
  String? memory,
  bool empty = false,
}) {
  const nothing = 'Сохранять нечего: на калькуляторе нет результата.';
  const noMemory = 'Память калькулятора пуста.';
  return switch (move) {
    CalculatorMove.chain || CalculatorMove.result => empty
        ? 'Калькулятор пуст. Скажите, что посчитать.'
        : calculationReply(value),
    CalculatorMove.memorySave =>
      value == null ? nothing : 'Сохранил в память: ${spokenNumber(value)}.',
    CalculatorMove.memoryAdd => value == null || memory == null
        ? nothing
        : 'Прибавил к памяти, там ${spokenNumber(memory)}.',
    CalculatorMove.memorySubtract => value == null || memory == null
        ? nothing
        : 'Вычел из памяти, там ${spokenNumber(memory)}.',
    CalculatorMove.memoryRead =>
      memory == null ? noMemory : 'В памяти ${spokenNumber(memory)}.',
    CalculatorMove.memoryRecall =>
      memory == null ? noMemory : 'Достал из памяти: ${spokenNumber(memory)}.',
    CalculatorMove.memoryClear => 'Память калькулятора очищена.',
    CalculatorMove.clear => 'Калькулятор очищен.',
    CalculatorMove.scientific => 'Включил инженерный калькулятор.',
    CalculatorMove.basic => 'Включил обычный калькулятор.',
    CalculatorMove.degrees => 'Углы считаю в градусах.',
    CalculatorMove.radians => 'Углы считаю в радианах.',
  };
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

/// Как просят посчитать: слов бывает несколько подряд — «посчитай, сколько
/// будет».
final _trigger = phrasePattern('^(?:(?:сколько\\s+(?:же\\s+)?(?:будет|получится'
    '|получается|выйдет|это\\s+будет)|(?:по|под|рас|со)считай(?:те)?'
    '|вычисли(?:те)?|прикинь(?:те)?|реши(?:\\s+пример)?|пожалуйста'
    '|чему\\s+(?:будет\\s+)?(?:равно|равен|равна)|как(?:ая|ой|ое)'
    '(?:\\s+будет)?|сколько)$wordEnd[\\s,]*)+');

/// «200 плюс 150 сколько будет» — вопрос после чисел.
final _askedAfter = phrasePattern('[\\s,]+(?:сколько(?:\\s+(?:будет|получится'
    '|выйдет))?|равно|будет)\$');

/// Действие, названное до чисел: «сложи 200 и 150» → «200+150».
final _namedActions = <(RegExp, String Function(String, String))>[
  (
    _named('(?:сложи|сложить|прибавь)\\s+N\\s+(?:и|с|к)\\s+N'),
    (a, b) => '$a+$b'
  ),
  (_named('сумм[аыу]\\s+(?:чисел\\s+)?N\\s+и\\s+N'), (a, b) => '$a+$b'),
  (
    _named('(?:вычти|вычесть|отними|отнять)\\s+N\\s+из\\s+N'),
    (a, b) => '$b-$a'
  ),
  (
    _named('(?:вычти|вычесть|отними|отнять)\\s+от\\s+N\\s+N'),
    (a, b) => '$a-$b'
  ),
  (
    _named('(?:разниц[аыу]|разност[ьи])\\s+(?:между\\s+)?N\\s+и\\s+N'),
    (a, b) => '$a-$b'
  ),
  (
    _named('(?:умножь|умножить|помножь|помножить)\\s+N\\s+на\\s+N'),
    (a, b) => '$a*$b'
  ),
  (_named('произведени[ея]\\s+N\\s+и\\s+N'), (a, b) => '$a*$b'),
  (
    _named('(?:раздели|разделить|подели|поделить)\\s+N\\s+на\\s+N'),
    (a, b) => '$a/$b'
  ),
  (
    _named('частное\\s+(?:от\\s+деления\\s+)?N\\s+(?:и|на)\\s+N'),
    (a, b) => '$a/$b'
  ),
];

/// Образец всей фразы, где N — число.
RegExp _named(String shape) =>
    phrasePattern('^${shape.replaceAll('N', '(\\d+(?:[.,]\\d+)?)')}\$');

final _hasOperator = RegExp(r'[+\-*/^%]|sqrt');

/// «На калькуляторе» — лишние слова: считает всегда он.
final _onCalculator =
    phrasePattern('\\s*(?:на|в)\\s+калькулятор[а-я]*$wordEnd');

/// «А теперь», «ещё» перед продолжением.
final _chainLead = phrasePattern('^(?:(?:а|и|ну)\\s+)?(?:(?:теперь|еще|потом'
    '|затем|дальше)\\s+)?');

/// Продолжение начинается с действия: «+10», «*3».
final _leadingAction = RegExp(r'^[+\-*/^](?=.*\d)');

final _chainWords = <(RegExp, String)>[
  (phrasePattern('^(?:раздели|подели|разделить|поделить)\\s+пополам\$'), '/2'),
  (phrasePattern('^(?:удвой|удвоить)\$'), '*2'),
  (phrasePattern('^(?:возведи\\s+)?в\\s+квадрат[а-я]*\$'), '^2'),
  (phrasePattern('^(?:возведи\\s+)?в\\s+куб[а-я]*\$'), '^3'),
  (
    phrasePattern('^(?:извлеки\\s+)?(?:квадратный\\s+)?корень'
        '(?:\\s+из\\s+(?:этого|него|результата))?\$'),
    'sqrt'
  ),
];

final _moves = <(RegExp, CalculatorMove)>[
  (
    phrasePattern('^(?:(?:сохрани|запиши|положи|запомни|занеси)(?:\\s+(?:это'
        '|его|результат|число))?\\s+)?в\\s+память\$'),
    CalculatorMove.memorySave
  ),
  (
    phrasePattern('^(?:прибавь|добавь|приплюсуй)(?:\\s+(?:это|его|результат))?'
        '\\s+(?:к\\s+памяти|в\\s+память)\$'),
    CalculatorMove.memoryAdd
  ),
  (
    phrasePattern('^(?:вычти|отними|убавь)(?:\\s+(?:это|его|результат))?'
        '\\s+из\\s+памяти\$'),
    CalculatorMove.memorySubtract
  ),
  (
    phrasePattern('^(?:что|сколько)(?:\\s+у\\s+тебя)?\\s+в\\s+памяти'
        '(?:\\s+калькулятора)?\$'),
    CalculatorMove.memoryRead
  ),
  (
    phrasePattern('^(?:достань|вставь|верни|возьми|подставь)(?:\\s+(?:число'
        '|результат))?\\s+из\\s+памяти\$'),
    CalculatorMove.memoryRecall
  ),
  (
    phrasePattern('^(?:очисти|сотри|обнули|сбрось)\\s+память'
        '(?:\\s+калькулятора)?\$'),
    CalculatorMove.memoryClear
  ),
  (
    phrasePattern('^(?:(?:очисти|сотри|обнули|сбрось)\\s+(?:все\\s+на\\s+)?'
        'калькулятор[а-я]*|сбрось|обнули)\$'),
    CalculatorMove.clear
  ),
  (
    phrasePattern('^(?:(?:и\\s+)?(?:сколько|что)\\s+(?:же\\s+)?(?:получилось'
        '|вышло)|какой\\s+(?:результат|итог)|что\\s+на\\s+калькуляторе)\$'),
    CalculatorMove.result
  ),
  (
    phrasePattern('(?:инженерн|научн)[а-я]*\\s+(?:калькулятор|режим)'),
    CalculatorMove.scientific
  ),
  (
    phrasePattern('(?:обычн|прост|стандартн)[а-я]*\\s+(?:калькулятор|режим)'),
    CalculatorMove.basic
  ),
  (phrasePattern('^(?:считай\\s+)?в\\s+радианах\$'), CalculatorMove.radians),
  (phrasePattern('^(?:считай\\s+)?в\\s+градусах\$'), CalculatorMove.degrees),
];

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
    phrasePattern(
        '$wordStart(?:минус|отнять|вычесть|отними|вычти|убавь)$wordEnd'),
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
