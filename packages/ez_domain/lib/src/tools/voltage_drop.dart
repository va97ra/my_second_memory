/// Падение напряжения в линии.
///
/// Считается по двум составляющим — активной и реактивной:
/// `ΔU = k · I · (R·cos φ + X·sin φ)`, где `k` равно 2 для однофазной линии
/// (ток идёт по жиле туда и возвращается по второй) и √3 для трёхфазной.
/// Потери мощности берутся от полного тока: `2·I²·R` и `3·I²·R`
/// соответственно — они не зависят от cos φ, в отличие от падения.
///
/// Ответ даётся дважды: для холодной жилы (20 °C) и для жилы под длительной
/// нагрузкой (70 °C). Нагретая жила сопротивляется сильнее, и с нормой
/// сравнивают именно её падение; холодное число показывает, сколько добавил
/// нагрев.
///
/// Удельное сопротивление при 20 °C: медь 0,0175, алюминий 0,0282 Ом·мм²/м.
/// Температурные коэффициенты: 0,00393 и 0,00403 1/°C.
///
/// Реактивное сопротивление взято по способу прокладки и **не сверено с
/// нормами** — как и таблицы допустимого тока в [wire_sizing]. Пока проверки
/// нет, интерфейс показывает эти условия рядом с ответом, а не прячет их.
library;

import 'dart:math' as math;

import 'numeric_guards.dart';
import 'wire_sizing.dart';

/// Стандартный ряд сечений, мм². Сечение выбирают из него, а не любое.
const standardSectionsMm2 = <double>[
  1.5,
  2.5,
  4,
  6,
  10,
  16,
  25,
  35,
  50,
  70,
  95,
  120,
];

/// Температура жилы без нагрузки, °C.
const coldConductorTemperatureC = 20.0;

/// Температура жилы под длительной нагрузкой, °C.
const hotConductorTemperatureC = 70.0;

/// Состояние линии при одной температуре жилы.
class ConductorState {
  const ConductorState({
    required this.temperatureC,
    required this.resistanceOhm,
    required this.reactanceOhm,
    required this.dropV,
    required this.dropPercent,
    required this.lossW,
  });

  /// Температура жилы, при которой посчитано сопротивление.
  final double temperatureC;

  /// Активное сопротивление одной жилы в одну сторону, Ом.
  final double resistanceOhm;

  /// Реактивное сопротивление одной жилы в одну сторону, Ом.
  final double reactanceOhm;

  final double dropV;
  final double dropPercent;

  /// Потери мощности в линии, Вт.
  final double lossW;
}

/// Падение напряжения в холодной и в нагретой жиле.
class VoltageDropResult {
  const VoltageDropResult({required this.cold, required this.hot});

  final ConductorState cold;
  final ConductorState hot;

  /// Укладывается ли нагретая жила в норму.
  bool withinLimit(double limitPercent) => hot.dropPercent <= limitPercent;
}

VoltageDropResult voltageDrop({
  required double currentA,
  required double oneWayLengthM,
  required double sectionMm2,
  required double voltageV,
  required bool threePhase,
  required ConductorMaterial material,
  required WireRouting routing,
  double powerFactor = 1,
}) {
  nonNegativeValue(currentA, 'currentA');
  nonNegativeValue(oneWayLengthM, 'oneWayLengthM');
  positiveValue(sectionMm2, 'sectionMm2');
  positiveValue(voltageV, 'voltageV');
  fractionValue(powerFactor, 'powerFactor');
  ConductorState at(double temperatureC) => _stateAt(
        temperatureC: temperatureC,
        currentA: currentA,
        oneWayLengthM: oneWayLengthM,
        sectionMm2: sectionMm2,
        voltageV: voltageV,
        threePhase: threePhase,
        material: material,
        routing: routing,
        powerFactor: powerFactor,
      );
  return VoltageDropResult(
    cold: at(coldConductorTemperatureC),
    hot: at(hotConductorTemperatureC),
  );
}

/// Наименьшее сечение из ряда, при котором нагретая жила укладывается в норму.
///
/// `null` — в ряду такого сечения нет: линию нужно делить, поднимать
/// напряжение или сокращать длину, а не брать «что-нибудь потолще».
double? minimumSectionForDrop({
  required double currentA,
  required double oneWayLengthM,
  required double voltageV,
  required bool threePhase,
  required ConductorMaterial material,
  required WireRouting routing,
  required double limitPercent,
  double powerFactor = 1,
}) {
  positiveValue(limitPercent, 'limitPercent');
  for (final section in standardSectionsMm2) {
    final result = voltageDrop(
      currentA: currentA,
      oneWayLengthM: oneWayLengthM,
      sectionMm2: section,
      voltageV: voltageV,
      threePhase: threePhase,
      material: material,
      routing: routing,
      powerFactor: powerFactor,
    );
    if (result.withinLimit(limitPercent)) return section;
  }
  return null;
}

ConductorState _stateAt({
  required double temperatureC,
  required double currentA,
  required double oneWayLengthM,
  required double sectionMm2,
  required double voltageV,
  required bool threePhase,
  required ConductorMaterial material,
  required WireRouting routing,
  required double powerFactor,
}) {
  final resistivity = _resistivityAt20[material]! *
      (1 +
          _temperatureCoefficient[material]! *
              (temperatureC - coldConductorTemperatureC));
  final resistance = resistivity * oneWayLengthM / sectionMm2;
  final reactance = _reactanceOhmPerKm[routing]! * oneWayLengthM / 1000;
  final sinPhi = math.sqrt(1 - powerFactor * powerFactor);
  final dropFactor = threePhase ? math.sqrt(3) : 2.0;
  final lossFactor = threePhase ? 3.0 : 2.0;
  final drop =
      dropFactor * currentA * (resistance * powerFactor + reactance * sinPhi);
  return ConductorState(
    temperatureC: temperatureC,
    resistanceOhm: resistance,
    reactanceOhm: reactance,
    dropV: drop,
    dropPercent: drop / voltageV * 100,
    lossW: lossFactor * currentA * currentA * resistance,
  );
}

/// Удельное сопротивление при 20 °C, Ом·мм²/м.
const _resistivityAt20 = <ConductorMaterial, double>{
  ConductorMaterial.copper: 0.0175,
  ConductorMaterial.aluminium: 0.0282,
};

/// Температурный коэффициент сопротивления, 1/°C.
const _temperatureCoefficient = <ConductorMaterial, double>{
  ConductorMaterial.copper: 0.00393,
  ConductorMaterial.aluminium: 0.00403,
};

/// Реактивное сопротивление линии, Ом/км.
///
/// Чем ближе жилы друг к другу, тем оно меньше: в трубе жилы лежат вплотную,
/// открытая проводка разнесена. Значения не сверены с нормами.
const _reactanceOhmPerKm = <WireRouting, double>{
  WireRouting.openAir: 0.30,
  WireRouting.conduitTwo: 0.08,
  WireRouting.conduitThree: 0.08,
};
