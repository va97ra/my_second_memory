import '../state/calculator_controller.dart';
import 'widgets/calculator_key.dart';

/// Раскладка клавиатуры: сами клавиши и на сколько столбцов их разложить.
///
/// Порядок в [keys] читается по строкам, поэтому число клавиш всегда кратно
/// [columns] — иначе последний ряд окажется рваным.
class CalculatorKeyLayout {
  const CalculatorKeyLayout({required this.columns, required this.keys})
      : assert(keys.length % columns == 0);

  final int columns;
  final List<String> keys;
}

const _standardKeys = [
  '%',
  'CE',
  'C',
  'backspace',
  'reciprocal',
  'square',
  'sqrt',
  '÷',
  '7',
  '8',
  '9',
  '×',
  '4',
  '5',
  '6',
  '−',
  '1',
  '2',
  '3',
  '+',
  'sign',
  '0',
  ',',
  '=',
];

final standardCalculatorLayout =
    CalculatorKeyLayout(columns: 4, keys: _standardKeys);

/// Инженерная клавиатура для высокого места: пять столбцов, восемь рядов.
/// Столбец действий `÷ × − + =` идёт сверху вниз одной полосой справа.
List<String> _tallScientificKeys(CalculatorState state) => [
      '2nd',
      'Hyp',
      'angle',
      'C',
      'backspace',
      state.second ? 'cube' : 'square',
      state.second ? 'root' : 'power',
      '10ˣ',
      'factorial',
      'Mod',
      'reciprocal',
      'abs',
      state.second ? 'cbrt' : 'sqrt',
      'e',
      'Exp',
      'sin',
      'cos',
      'tan',
      'pi',
      '÷',
      'ln',
      '7',
      '8',
      '9',
      '×',
      'log',
      '4',
      '5',
      '6',
      '−',
      '(',
      '1',
      '2',
      '3',
      '+',
      ')',
      'sign',
      '0',
      ',',
      '=',
    ];

/// Инженерная клавиатура для широкого места: восемь столбцов, пять рядов.
///
/// Это не разрезанная пополам высокая раскладка, а своя: слева блок функций,
/// справа — тот же цифровой блок со столбцом действий, что и на телефоне.
/// Разрез по счёту клавиш ставил `÷` посреди клавиатуры, отдельно от
/// `× − + =`, и уводил `C` с `⌫` из угла в середину.
List<String> _wideScientificKeys(CalculatorState state) => [
      '2nd',
      'Hyp',
      'angle',
      'Exp',
      'C',
      'backspace',
      'Mod',
      '÷',
      state.second ? 'cube' : 'square',
      state.second ? 'root' : 'power',
      '10ˣ',
      'factorial',
      '7',
      '8',
      '9',
      '×',
      'reciprocal',
      'abs',
      state.second ? 'cbrt' : 'sqrt',
      'e',
      '4',
      '5',
      '6',
      '−',
      'sin',
      'cos',
      'tan',
      'pi',
      '1',
      '2',
      '3',
      '+',
      'ln',
      'log',
      '(',
      ')',
      'sign',
      '0',
      ',',
      '=',
    ];

/// Раскладка под форму места, которое досталось клавиатуре.
///
/// Решает не ширина экрана, а пропорции самого места: на планшете в портрете
/// широкая раскладка растягивала пять рядов на всю высоту и превращала
/// клавиши в вертикальные плашки.
CalculatorKeyLayout scientificCalculatorLayout(
  CalculatorState state, {
  required bool wide,
}) =>
    wide
        ? CalculatorKeyLayout(columns: 8, keys: _wideScientificKeys(state))
        : CalculatorKeyLayout(columns: 5, keys: _tallScientificKeys(state));

/// Чем клавиша занята. Знание одно на обе раскладки: столбец действий узнают
/// по знаку, а не по месту в списке.
CalculatorKeyRole calculatorKeyRole(String key) => switch (key) {
      '=' => CalculatorKeyRole.result,
      '÷' || '×' || '−' || '+' => CalculatorKeyRole.operation,
      _ => CalculatorKeyRole.plain,
    };
