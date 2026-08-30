import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import 'calculator_types.dart';

class CalculatorNumber {
  const CalculatorNumber._(this.exact, this.approximate);

  factory CalculatorNumber.exact(Decimal value) =>
      CalculatorNumber._(value, value.toDouble());
  factory CalculatorNumber.approximate(double value) =>
      CalculatorNumber._(null, value);

  final Decimal? exact;
  final double approximate;

  double get asDouble => exact?.toDouble() ?? approximate;

  CalculatorNumber operator -() => exact == null
      ? CalculatorNumber.approximate(-approximate)
      : CalculatorNumber.exact(-exact!);
  CalculatorNumber operator +(CalculatorNumber other) =>
      _binary(other, (a, b) => a + b, (a, b) => a + b);
  CalculatorNumber operator -(CalculatorNumber other) =>
      _binary(other, (a, b) => a - b, (a, b) => a - b);
  CalculatorNumber operator *(CalculatorNumber other) =>
      _binary(other, (a, b) => a * b, (a, b) => a * b);

  CalculatorNumber operator /(CalculatorNumber other) {
    if (other.asDouble == 0) {
      throw const CalculatorFailure(CalculatorError.divisionByZero);
    }
    if (exact != null && other.exact != null) {
      return CalculatorNumber.exact(
        (exact! / other.exact!).toDecimal(scaleOnInfinitePrecision: 34),
      );
    }
    return CalculatorNumber.approximate(asDouble / other.asDouble);
  }

  CalculatorNumber modulo(CalculatorNumber other) {
    if (other.asDouble == 0) {
      throw const CalculatorFailure(CalculatorError.divisionByZero);
    }
    if (exact != null && other.exact != null) {
      return CalculatorNumber.exact(exact! % other.exact!);
    }
    return CalculatorNumber.approximate(asDouble % other.asDouble);
  }

  CalculatorNumber power(CalculatorNumber exponent) {
    final exponentValue = exponent.asDouble;
    if (exact != null &&
        exponent.exact != null &&
        exponentValue == exponentValue.truncateToDouble() &&
        exponentValue.abs() <= 10000) {
      final integer = exponentValue.toInt();
      var result = Decimal.one;
      for (var i = 0; i < integer.abs(); i++) {
        result *= exact!;
      }
      return integer < 0
          ? CalculatorNumber.exact(
              (Decimal.one / result).toDecimal(scaleOnInfinitePrecision: 34),
            )
          : CalculatorNumber.exact(result);
    }
    final result = math.pow(asDouble, exponentValue).toDouble();
    if (!result.isFinite || result.isNaN) {
      throw const CalculatorFailure(CalculatorError.domain);
    }
    return CalculatorNumber.approximate(result);
  }

  CalculatorNumber factorial() {
    final value = asDouble;
    if (value < 0 || value != value.truncateToDouble()) {
      throw const CalculatorFailure(CalculatorError.domain);
    }
    if (value > 5000) {
      throw const CalculatorFailure(CalculatorError.factorialTooLarge);
    }
    var result = BigInt.one;
    for (var i = 2; i <= value.toInt(); i++) {
      result *= BigInt.from(i);
    }
    return CalculatorNumber.exact(Decimal.fromBigInt(result));
  }

  CalculatorNumber abs() => asDouble < 0 ? -this : this;

  CalculatorNumber _binary(
    CalculatorNumber other,
    Decimal Function(Decimal, Decimal) exactOperation,
    double Function(double, double) approximateOperation,
  ) {
    if (exact != null && other.exact != null) {
      return CalculatorNumber.exact(exactOperation(exact!, other.exact!));
    }
    return CalculatorNumber.approximate(
      approximateOperation(asDouble, other.asDouble),
    );
  }
}

class CalculatorFailure implements Exception {
  const CalculatorFailure(this.error);

  final CalculatorError error;
}
