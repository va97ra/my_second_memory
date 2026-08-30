import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import 'calculator_lexer.dart';
import 'calculator_number.dart';
import 'calculator_types.dart';

class CalculatorEngine {
  const CalculatorEngine();

  CalculatorEvaluation evaluate(
    String expression, {
    CalculatorAngleUnit angleUnit = CalculatorAngleUnit.degrees,
  }) {
    final source = expression
        .trim()
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(',', '.');
    if (source.isEmpty) return const CalculatorEvaluation.incomplete();
    try {
      final parser = _Parser(CalculatorLexer(source).tokens(), angleUnit);
      final value = parser.parse();
      return CalculatorEvaluation.valid(_format(value));
    } on _IncompleteExpression {
      return const CalculatorEvaluation.incomplete();
    } on CalculatorIncompleteInput {
      return const CalculatorEvaluation.incomplete();
    } on CalculatorFailure catch (failure) {
      return CalculatorEvaluation.error(failure.error);
    } on FormatException {
      return const CalculatorEvaluation.error(
        CalculatorError.invalidExpression,
      );
    }
  }

  String _format(CalculatorNumber value) {
    if (value.exact case final decimal?) {
      return _trimDecimal(decimal.toString());
    }
    final approximate = value.approximate;
    if (!approximate.isFinite) {
      throw const CalculatorFailure(CalculatorError.domain);
    }
    final magnitude = approximate == 0 ? 0 : approximate.abs();
    final formatted = magnitude != 0 && (magnitude >= 1e15 || magnitude < 1e-9)
        ? approximate.toStringAsExponential(12)
        : approximate.toStringAsPrecision(15);
    return _trimDecimal(formatted);
  }
}

String _trimDecimal(String value) {
  final parts = value.toLowerCase().split('e');
  var mantissa = parts.first;
  if (mantissa.contains('.')) {
    mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '');
    mantissa = mantissa.replaceFirst(RegExp(r'\.$'), '');
  }
  if (mantissa == '-0') mantissa = '0';
  if (parts.length == 1) return mantissa;
  final exponent = int.parse(parts.last);
  return '${mantissa}e${exponent >= 0 ? '+' : ''}$exponent';
}

class _Parser {
  _Parser(this.tokens, this.angleUnit);
  final List<CalculatorToken> tokens;
  final CalculatorAngleUnit angleUnit;
  var index = 0;

  CalculatorToken get current => tokens[index];
  CalculatorToken take() => tokens[index++];

  CalculatorNumber parse() {
    final value = _additive();
    if (current.kind != CalculatorTokenKind.end) {
      throw const CalculatorFailure(CalculatorError.invalidExpression);
    }
    return value.number;
  }

  _Value _additive() {
    var left = _multiplicative();
    while (current.kind == CalculatorTokenKind.plus ||
        current.kind == CalculatorTokenKind.minus) {
      final operator = take().kind;
      final right = _multiplicative();
      final operand =
          right.isPercent ? left.number * right.number : right.number;
      left = _Value(
        operator == CalculatorTokenKind.plus
            ? left.number + operand
            : left.number - operand,
      );
    }
    return left;
  }

  _Value _multiplicative() {
    var left = _unary();
    while (current.kind == CalculatorTokenKind.multiply ||
        current.kind == CalculatorTokenKind.divide ||
        (current.kind == CalculatorTokenKind.percent &&
            current.text == 'mod')) {
      final operator = take();
      final right = _unary();
      left = _Value(switch (operator.kind) {
        CalculatorTokenKind.multiply => left.number * right.number,
        CalculatorTokenKind.divide => left.number / right.number,
        _ => left.number.modulo(right.number),
      });
    }
    return left;
  }

  _Value _power() {
    var left = _postfix();
    if (current.kind == CalculatorTokenKind.power) {
      take();
      left = _Value(left.number.power(_unary().number));
    }
    return left;
  }

  _Value _unary() {
    if (current.kind == CalculatorTokenKind.plus) {
      take();
      return _unary();
    }
    if (current.kind == CalculatorTokenKind.minus) {
      take();
      return _Value(-_unary().number);
    }
    return _power();
  }

  _Value _postfix() {
    var value = _primary();
    while (current.kind == CalculatorTokenKind.percent ||
        current.kind == CalculatorTokenKind.factorial) {
      if (current.kind == CalculatorTokenKind.percent &&
          current.text != 'mod') {
        take();
        value = _Value(
            value.number / CalculatorNumber.exact(Decimal.fromInt(100)),
            isPercent: true);
      } else if (current.kind == CalculatorTokenKind.factorial) {
        take();
        value = _Value(value.number.factorial());
      } else {
        break;
      }
    }
    return value;
  }

  _Value _primary() {
    if (current.kind == CalculatorTokenKind.end) {
      throw const _IncompleteExpression();
    }
    if (current.kind == CalculatorTokenKind.number) {
      final token = take();
      try {
        return _Value(CalculatorNumber.exact(Decimal.parse(token.text)));
      } on FormatException {
        throw const CalculatorFailure(CalculatorError.invalidExpression);
      }
    }
    if (current.kind == CalculatorTokenKind.left) {
      take();
      final value = _additive();
      if (current.kind == CalculatorTokenKind.end) {
        throw const _IncompleteExpression();
      }
      if (current.kind != CalculatorTokenKind.right) {
        throw const CalculatorFailure(CalculatorError.invalidExpression);
      }
      take();
      return value;
    }
    if (current.kind == CalculatorTokenKind.identifier) {
      final name = take().text;
      if (name == 'π' || name == 'pi') {
        return _Value(CalculatorNumber.approximate(math.pi));
      }
      if (name == 'e') {
        return _Value(CalculatorNumber.approximate(math.e));
      }
      if (current.kind != CalculatorTokenKind.left) {
        throw const CalculatorFailure(CalculatorError.invalidExpression);
      }
      take();
      final arguments = <CalculatorNumber>[];
      if (current.kind != CalculatorTokenKind.right) {
        while (true) {
          arguments.add(_additive().number);
          if (current.kind != CalculatorTokenKind.comma) break;
          take();
        }
      }
      if (current.kind == CalculatorTokenKind.end) {
        throw const _IncompleteExpression();
      }
      if (current.kind != CalculatorTokenKind.right) {
        throw const CalculatorFailure(CalculatorError.invalidExpression);
      }
      take();
      return _Value(_function(name, arguments));
    }
    throw const CalculatorFailure(CalculatorError.invalidExpression);
  }

  CalculatorNumber _function(String name, List<CalculatorNumber> args) {
    if (args.length != (name == 'root' ? 2 : 1)) {
      throw const CalculatorFailure(CalculatorError.invalidExpression);
    }
    final x = args.first.asDouble;
    final radians = switch (angleUnit) {
      CalculatorAngleUnit.degrees => x * math.pi / 180,
      CalculatorAngleUnit.radians => x,
      CalculatorAngleUnit.gradians => x * math.pi / 200,
    };
    double result;
    switch (name) {
      case 'sin':
        result = math.sin(radians);
        break;
      case 'cos':
        result = math.cos(radians);
        break;
      case 'tan':
        if (math.cos(radians).abs() < 1e-14) {
          throw const CalculatorFailure(CalculatorError.domain);
        }
        result = math.tan(radians);
        break;
      case 'asin':
        result = _fromRadians(math.asin(x));
        break;
      case 'acos':
        result = _fromRadians(math.acos(x));
        break;
      case 'atan':
        result = _fromRadians(math.atan(x));
        break;
      case 'sinh':
        result = (math.exp(x) - math.exp(-x)) / 2;
        break;
      case 'cosh':
        result = (math.exp(x) + math.exp(-x)) / 2;
        break;
      case 'tanh':
        result = x.abs() > 20
            ? x.sign
            : (math.exp(2 * x) - 1) / (math.exp(2 * x) + 1);
        break;
      case 'asinh':
        result = math.log(x + math.sqrt(x * x + 1));
        break;
      case 'acosh':
        result = math.log(x + math.sqrt(x * x - 1));
        break;
      case 'atanh':
        result = 0.5 * math.log((1 + x) / (1 - x));
        break;
      case 'sqrt':
        result = math.sqrt(x);
        break;
      case 'cbrt':
        result = x < 0
            ? -math.pow(-x, 1 / 3).toDouble()
            : math.pow(x, 1 / 3).toDouble();
        break;
      case 'abs':
        return args.first.abs();
      case 'ln':
        result = math.log(x);
        break;
      case 'log':
        result = math.log(x) / math.ln10;
        break;
      case 'exp':
        result = math.exp(x);
        break;
      case 'exp10':
        result = math.pow(10, x).toDouble();
        break;
      case 'exp2':
        result = math.pow(2, x).toDouble();
        break;
      case 'root':
        final degree = args[1].asDouble;
        if (degree == 0) {
          throw const CalculatorFailure(CalculatorError.domain);
        }
        if (x < 0) {
          if (degree != degree.truncateToDouble() || degree.toInt().isEven) {
            throw const CalculatorFailure(CalculatorError.domain);
          }
          result = -math.pow(-x, 1 / degree).toDouble();
        } else {
          result = math.pow(x, 1 / degree).toDouble();
        }
        break;
      default:
        throw const CalculatorFailure(CalculatorError.invalidExpression);
    }
    if (!result.isFinite || result.isNaN) {
      throw const CalculatorFailure(CalculatorError.domain);
    }
    return CalculatorNumber.approximate(result);
  }

  double _fromRadians(double value) => switch (angleUnit) {
        CalculatorAngleUnit.degrees => value * 180 / math.pi,
        CalculatorAngleUnit.radians => value,
        CalculatorAngleUnit.gradians => value * 200 / math.pi,
      };
}

class _Value {
  const _Value(this.number, {this.isPercent = false});
  final CalculatorNumber number;
  final bool isPercent;
}

class _IncompleteExpression implements Exception {
  const _IncompleteExpression();
}
