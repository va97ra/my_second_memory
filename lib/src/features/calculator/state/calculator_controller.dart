import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final calculatorControllerProvider =
    StateNotifierProvider<CalculatorController, CalculatorState>((ref) {
  return CalculatorController();
});

class CalculatorState {
  const CalculatorState({
    this.expression = '',
    this.evaluation = const CalculatorEvaluation.incomplete(),
    this.scientific = false,
    this.second = false,
    this.hyperbolic = false,
    this.angleUnit = CalculatorAngleUnit.degrees,
    this.memory,
  });

  final String expression;
  final CalculatorEvaluation evaluation;
  final bool scientific;
  final bool second;
  final bool hyperbolic;
  final CalculatorAngleUnit angleUnit;
  final String? memory;

  CalculatorState copyWith({
    String? expression,
    CalculatorEvaluation? evaluation,
    bool? scientific,
    bool? second,
    bool? hyperbolic,
    CalculatorAngleUnit? angleUnit,
    String? memory,
    bool clearMemory = false,
  }) {
    return CalculatorState(
      expression: expression ?? this.expression,
      evaluation: evaluation ?? this.evaluation,
      scientific: scientific ?? this.scientific,
      second: second ?? this.second,
      hyperbolic: hyperbolic ?? this.hyperbolic,
      angleUnit: angleUnit ?? this.angleUnit,
      memory: clearMemory ? null : memory ?? this.memory,
    );
  }
}

class CalculatorController extends StateNotifier<CalculatorState> {
  CalculatorController() : super(const CalculatorState());

  static const _engine = CalculatorEngine();

  void updateExpression(String expression) {
    state = state.copyWith(
      expression: expression,
      evaluation: _engine.evaluate(expression, angleUnit: state.angleUnit),
    );
  }

  void setScientific(bool value) => state = state.copyWith(scientific: value);
  void toggleSecond() => state = state.copyWith(second: !state.second);
  void toggleHyperbolic() =>
      state = state.copyWith(hyperbolic: !state.hyperbolic);

  void cycleAngleUnit() {
    final next = CalculatorAngleUnit.values[
        (state.angleUnit.index + 1) % CalculatorAngleUnit.values.length];
    state = state.copyWith(
      angleUnit: next,
      evaluation: _engine.evaluate(state.expression, angleUnit: next),
    );
  }

  void commit() {
    if (state.evaluation.status == CalculatorEvaluationStatus.incomplete) {
      state = state.copyWith(
        evaluation: const CalculatorEvaluation.error(
          CalculatorError.invalidExpression,
        ),
      );
    }
  }

  void memoryCommand(String command) {
    final result = state.evaluation.value;
    switch (command) {
      case 'MC':
        state = state.copyWith(clearMemory: true);
        return;
      case 'MR':
        if (state.memory != null) updateExpression(state.memory!);
        return;
      case 'MS':
        if (result != null) state = state.copyWith(memory: result);
        return;
      case 'M+':
      case 'M-':
        if (result == null) return;
        final memory = state.memory ?? '0';
        final evaluation = _engine.evaluate(
          '$memory${command == 'M+' ? '+' : '-'}($result)',
        );
        if (evaluation.value != null) {
          state = state.copyWith(memory: evaluation.value);
        }
        return;
    }
  }
}
