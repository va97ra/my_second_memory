import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = CalculatorEngine();

  test('evaluates a complete expression with precedence', () {
    expect(engine.evaluate('158+26-946+50').value, '-712');
    expect(engine.evaluate('2+3*4').value, '14');
    expect(engine.evaluate('(2+3)*4').value, '20');
    expect(engine.evaluate('-2^2').value, '-4');
    expect(engine.evaluate('2^-2').value, '0.25');
  });

  test('keeps basic decimal arithmetic exact', () {
    expect(engine.evaluate('0.1+0.2').value, '0.3');
  });

  test('uses contextual calculator percentages', () {
    expect(engine.evaluate('100+10%').value, '110');
    expect(engine.evaluate('200*10%').value, '20');
    expect(engine.evaluate('100+10%-5%').value, '104.5');
    expect(engine.evaluate('17mod5').value, '2');
  });

  test('supports angle units and scientific functions', () {
    expect(engine.evaluate('sin(30)').value, '0.5');
    expect(
      engine
          .evaluate('sin(1.5707963267948966)',
              angleUnit: CalculatorAngleUnit.radians)
          .value,
      '1',
    );
    expect(engine.evaluate('5!').value, '120');
    expect(engine.evaluate('2^10').value, '1024');
    expect(engine.evaluate('asin(0.5)').value, '30');
    expect(
        engine
            .evaluate('sin(100)', angleUnit: CalculatorAngleUnit.gradians)
            .value,
        '1');
    expect(engine.evaluate('asinh(0)').value, '0');
    expect(engine.evaluate('root(-8;3)').value, '-2');
  });

  test('distinguishes incomplete input and math errors', () {
    expect(engine.evaluate('2+').status, CalculatorEvaluationStatus.incomplete);
    expect(engine.evaluate('1e').status, CalculatorEvaluationStatus.incomplete);
    expect(
        engine.evaluate('1e-').status, CalculatorEvaluationStatus.incomplete);
    expect(engine.evaluate('1/0').error, CalculatorError.divisionByZero);
    expect(engine.evaluate('sqrt(-1)').error, CalculatorError.domain);
    expect(engine.evaluate('tan(90)').error, CalculatorError.domain);
    expect(engine.evaluate('5001!').error, CalculatorError.factorialTooLarge);
  });
}
