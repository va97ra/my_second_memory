/// Клавиши калькулятора, которые меняют всё выражение, а не вставляют знак
/// у курсора. Правило одно на палец и на Джарвиса: нажимают они одинаково.
///
/// Модель — виндовая (решение владельца 9 сентября 2026): `x²`, `√`, `1/x` и
/// `±` берут всё выражение, а не последнее число. Null — клавиша просто
/// вставляет свой знак.
String? wholeExpressionKey(String key, String expression) => switch (key) {
      'C' => '',
      // Число стирается тем же набором знаков, каким его набирают: клавиша
      // разделителя ставит запятую, и без неё «12,5» теряло только пятёрку.
      'CE' => expression.replaceFirst(RegExp(r'[\d.,]+$'), ''),
      'square' => '($expression)^2',
      'cube' => '($expression)^3',
      'reciprocal' => '1/($expression)',
      'sign' =>
        expression.startsWith('-') ? expression.substring(1) : '-($expression)',
      'root' => 'root($expression;',
      _ => null,
    };

/// Всё выражение — аргументом функции: `sqrt(25+4)`. Пустое имя — просто
/// скобки.
String wrapExpression(String function, String expression) =>
    '$function($expression)';

/// Есть ли сложение или вычитание вне скобок. Тогда результат умножают,
/// взяв выражение в скобки: `(25+4)×3`, а не `25+4×3`.
bool hasLooseSum(String expression) {
  var depth = 0;
  for (var i = 0; i < expression.length; i++) {
    final char = expression[i];
    if (char == '(') depth++;
    if (char == ')') depth--;
    if (depth != 0 || i == 0 || !_sums.contains(char)) continue;
    // Знак числа, а не действие: в начале скобки, после действия и в
    // порядке числа — `2E-3`.
    if (!_signLeaders.contains(expression[i - 1])) return true;
  }
  return false;
}

/// Действия так, как их пишут клавиши: `×`, `÷`, `−`.
String keyedExpression(String expression) =>
    expression.replaceAll('*', '×').replaceAll('/', '÷').replaceAll('-', '−');

const _sums = {'+', '-', '−'};
const _signLeaders = {'(', '+', '-', '−', '*', '×', '/', '÷', '^', 'E', ';'};
