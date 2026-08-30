import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/calculator/state/calculator_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('memory commands stay exact for the application session', () {
    final controller = CalculatorController();
    addTearDown(controller.dispose);
    controller.updateExpression('0.1+0.2');
    controller.memoryCommand('MS');
    expect(controller.state.memory, '0.3');

    controller.updateExpression('0.2');
    controller.memoryCommand('M+');
    expect(controller.state.memory, '0.5');

    controller.memoryCommand('M-');
    expect(controller.state.memory, '0.3');
    controller.updateExpression('999');
    controller.memoryCommand('MR');
    expect(controller.state.expression, '0.3');
    controller.memoryCommand('MC');
    expect(controller.state.memory, isNull);
  });

  test('equals turns incomplete input into an explicit error', () {
    final controller = CalculatorController();
    addTearDown(controller.dispose);
    controller.updateExpression('2+');
    expect(
      controller.state.evaluation.status,
      CalculatorEvaluationStatus.incomplete,
    );

    controller.commit();

    expect(
      controller.state.evaluation.error,
      CalculatorError.invalidExpression,
    );
    controller.updateExpression('2+2');
    expect(controller.state.evaluation.value, '4');
  });
}
