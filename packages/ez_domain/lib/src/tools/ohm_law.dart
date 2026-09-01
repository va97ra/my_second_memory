/// Закон Ома для участка цепи и мощность постоянного тока.
///
/// Три величины связаны одним равенством `U = I · R`, и любая из них
/// находится по двум другим. Мощность считается по найденной паре:
/// `P = U · I`.
///
/// Для цепи переменного тока это верно только при активной нагрузке. Как
/// только появляется cos φ, мощность считают в расчёте мощности, а не здесь.
library;

import 'numeric_guards.dart';

/// Величина, которую ищут.
enum OhmLawUnknown { voltage, current, resistance }

class OhmLawResult {
  const OhmLawResult({
    required this.unknown,
    required this.voltageV,
    required this.currentA,
    required this.resistanceOhm,
    required this.powerW,
  });

  final OhmLawUnknown unknown;
  final double voltageV;
  final double currentA;
  final double resistanceOhm;
  final double powerW;

  /// Найденное значение — то, ради чего считали.
  double get value => switch (unknown) {
        OhmLawUnknown.voltage => voltageV,
        OhmLawUnknown.current => currentA,
        OhmLawUnknown.resistance => resistanceOhm,
      };
}

/// Считает недостающую величину по двум известным.
///
/// Ноль в знаменателе не заменяется бесконечностью и не проглатывается:
/// цепи с нулевым сопротивлением или нулевым током у закона Ома нет.
OhmLawResult solveOhmLaw({
  required OhmLawUnknown unknown,
  double? voltageV,
  double? currentA,
  double? resistanceOhm,
}) {
  switch (unknown) {
    case OhmLawUnknown.voltage:
      final current = _required(currentA, 'currentA');
      final resistance = _required(resistanceOhm, 'resistanceOhm');
      nonNegativeValue(current, 'currentA');
      positiveValue(resistance, 'resistanceOhm');
      return _result(unknown, current * resistance, current, resistance);
    case OhmLawUnknown.current:
      final voltage = _required(voltageV, 'voltageV');
      final resistance = _required(resistanceOhm, 'resistanceOhm');
      nonNegativeValue(voltage, 'voltageV');
      positiveValue(resistance, 'resistanceOhm');
      return _result(unknown, voltage, voltage / resistance, resistance);
    case OhmLawUnknown.resistance:
      final voltage = _required(voltageV, 'voltageV');
      final current = _required(currentA, 'currentA');
      nonNegativeValue(voltage, 'voltageV');
      positiveValue(current, 'currentA');
      return _result(unknown, voltage, current, voltage / current);
  }
}

OhmLawResult _result(
  OhmLawUnknown unknown,
  double voltageV,
  double currentA,
  double resistanceOhm,
) =>
    OhmLawResult(
      unknown: unknown,
      voltageV: voltageV,
      currentA: currentA,
      resistanceOhm: resistanceOhm,
      powerW: voltageV * currentA,
    );

double _required(double? value, String name) {
  if (value == null) {
    throw ArgumentError.notNull(name);
  }
  return value;
}
