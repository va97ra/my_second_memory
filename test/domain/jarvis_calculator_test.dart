import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Калькулятор голосом: какие фразы во что превращаются и как Джарвис
/// нажимает клавиши. Считает только калькулятор — Джарвис нажимает и читает.
void main() {
  final now = DateTime(2099, 10, 7, 14);
  JarvisCommand? parse(String phrase) =>
      const JarvisCommandParser().parse(phrase, now);

  CalculatorMove? move(String phrase) {
    final command = parse(phrase);
    return command is CalculatorCommand ? command.move : null;
  }

  String? tail(String phrase) {
    final command = parse(phrase);
    return command is CalculatorCommand && command.move == CalculatorMove.chain
        ? command.tail
        : null;
  }

  group('продолжить от того, что на калькуляторе', () {
    test('действие с числом', () {
      expect(tail('прибавь 10'), '+10');
      expect(tail('плюс 10'), '+10');
      expect(tail('а теперь умножь на 3'), '*3');
      expect(tail('теперь раздели на 4'), '/4');
      expect(tail('вычти 5'), '-5');
      expect(tail('минус 5'), '-5');
      expect(tail('ещё прибавь двадцать'), '+20');
    });

    test('действие без числа', () {
      expect(tail('раздели пополам'), '/2');
      expect(tail('удвой'), '*2');
      expect(tail('возведи в квадрат'), '^2');
      expect(tail('в куб'), '^3');
      expect(tail('извлеки корень'), 'sqrt');
      expect(tail('корень из этого'), 'sqrt');
    });

    test('«сколько будет» — новый счёт, а не продолжение', () {
      final command = parse('сколько будет 25 на 4');
      expect(command, isA<Calculate>());
      expect((command as Calculate).expression, '25*4');
      expect(command.show, isFalse);
      expect(parse('сколько будет минус 5'), isA<Calculate>());
    });

    test('«на калькуляторе» — посчитать и показать', () {
      final command = parse('посчитай на калькуляторе 25 на 4');
      expect((command as Calculate).expression, '25*4');
      expect(command.show, isTrue);
    });
  });

  test('все способы попросить посчитать', () {
    String? asked(String phrase) {
      final command = parse(phrase);
      return command is Calculate ? command.expression : null;
    }

    expect(asked('сложи 200 и 150'), '200+150');
    expect(asked('сложи 200 с 150'), '200+150');
    expect(asked('сумма 200 и 150'), '200+150');
    expect(asked('какая будет сумма 200 и 150'), '200+150');
    expect(asked('вычти 50 из 200'), '200-50');
    expect(asked('отними от 200 50'), '200-50');
    expect(asked('разница между 200 и 150'), '200-150');
    expect(asked('умножь 25 на 4'), '25*4');
    expect(asked('произведение 25 и 4'), '25*4');
    expect(asked('раздели 100 на 4'), '100/4');
    expect(asked('подели 100 на 4'), '100/4');
    expect(asked('чему равно 200 плюс 150'), '200+150');
    expect(asked('прикинь 200 плюс 150'), '200+150');
    expect(asked('посчитай сколько будет 200 плюс 150'), '200+150');
    expect(asked('посчитай, пожалуйста, 200 плюс 150'), '200+150');
    expect(asked('200 плюс 150 сколько будет'), '200+150');
    expect(asked('сколько получается 200 плюс 150'), '200+150');
    expect(asked('сколько выйдет 200 на 3'), '200*3');
    expect(asked('реши пример 200 плюс 150'), '200+150');
    expect(asked('двести плюс сто пятьдесят'), '200+150');
    expect(parse('какая погода завтра'), isNot(isA<Calculate>()));
  });

  test('ответ называет, что посчитано', () {
    expect(
        calculationReply('350', asked: '200+150'), '200 плюс 150 — будет 350.');
    expect(calculationReply('100', asked: '25*4'),
        '25 умножить на 4 — будет 100.');
    expect(calculationReply('1024', asked: '2^10'), 'Получается 1024.');
  });

  test('память, сброс, режимы и результат', () {
    expect(move('сохрани в память'), CalculatorMove.memorySave);
    expect(move('запиши результат в память'), CalculatorMove.memorySave);
    expect(move('прибавь к памяти'), CalculatorMove.memoryAdd);
    expect(move('вычти из памяти'), CalculatorMove.memorySubtract);
    expect(move('что в памяти'), CalculatorMove.memoryRead);
    expect(move('достань из памяти'), CalculatorMove.memoryRecall);
    expect(move('очисти память'), CalculatorMove.memoryClear);
    expect(move('очисти калькулятор'), CalculatorMove.clear);
    expect(move('сбрось'), CalculatorMove.clear);
    expect(move('сколько получилось'), CalculatorMove.result);
    expect(move('включи инженерный калькулятор'), CalculatorMove.scientific);
    expect(move('обычный калькулятор'), CalculatorMove.basic);
    expect(move('считай в радианах'), CalculatorMove.radians);
    expect(move('в градусах'), CalculatorMove.degrees);
  });

  test('чужие фразы калькулятор не забирает', () {
    expect(parse('запомни, что мама любит белые розы'), isA<RememberFact>());
    expect(parse('открой калькулятор'), isA<OpenPlace>());
    expect(parse('что ты обо мне знаешь'), isA<ListFacts>());
    expect(move('завтра в 10 врач'), isNull);
  });

  group('клавиши — одно правило на палец и на Джарвиса', () {
    test('x², 1/x и ± берут всё выражение', () {
      expect(wholeExpressionKey('square', '25+4'), '(25+4)^2');
      expect(wholeExpressionKey('reciprocal', '4'), '1/(4)');
      expect(wholeExpressionKey('C', '25+4'), '');
      expect(wholeExpressionKey('7', '25+4'), isNull);
    });

    test('умножают результат, а не последнее число', () {
      expect(hasLooseSum('25+4'), isTrue);
      expect(hasLooseSum('25×4'), isFalse);
      expect(hasLooseSum('-5×2'), isFalse);
      expect(hasLooseSum('(25+4)×3'), isFalse);
      expect(hasLooseSum('2E-3×4'), isFalse);
    });

    test('знаки — как на клавишах', () {
      expect(keyedExpression('25*4-3/2'), '25×4−3÷2');
    });
  });

  test('ответы', () {
    expect(calculationReply('110'), 'Получается 110.');
    expect(calculationReply(null), startsWith('Не сумел'));
    expect(calculatorReply(CalculatorMove.memorySave, value: '110'),
        'Сохранил в память: 110.');
    expect(calculatorReply(CalculatorMove.memoryRead),
        'Память калькулятора пуста.');
    expect(calculatorReply(CalculatorMove.result, empty: true),
        startsWith('Калькулятор пуст'));
  });
}
