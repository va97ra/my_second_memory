enum CalculatorAngleUnit { degrees, radians, gradians }

enum CalculatorEvaluationStatus { incomplete, valid, error }

enum CalculatorError {
  invalidExpression,
  divisionByZero,
  domain,
  factorialTooLarge,
}

class CalculatorEvaluation {
  const CalculatorEvaluation._({
    required this.status,
    this.value,
    this.error,
  });

  const CalculatorEvaluation.incomplete()
      : this._(status: CalculatorEvaluationStatus.incomplete);

  const CalculatorEvaluation.valid(String value)
      : this._(status: CalculatorEvaluationStatus.valid, value: value);

  const CalculatorEvaluation.error(CalculatorError error)
      : this._(status: CalculatorEvaluationStatus.error, error: error);

  final CalculatorEvaluationStatus status;
  final String? value;
  final CalculatorError? error;

  bool get isValid => status == CalculatorEvaluationStatus.valid;
}
