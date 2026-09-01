import 'dart:math' as math;

import 'numeric_guards.dart';

class AcPowerResult {
  const AcPowerResult({required this.activePowerW, required this.currentA});

  final double activePowerW;
  final double currentA;
}

class FlowSectionResult {
  const FlowSectionResult({
    required this.areaM2,
    required this.velocityMs,
    required this.diameterM,
  });

  final double areaM2;
  final double velocityMs;
  final double diameterM;
}

class PressureLossResult {
  const PressureLossResult({
    required this.reynolds,
    required this.velocityMs,
    required this.lossPa,
    required this.lossPaPerM,
  });

  final double reynolds;
  final double velocityMs;
  final double lossPa;
  final double lossPaPerM;
}

class DuctResult {
  const DuctResult({
    required this.areaM2,
    required this.velocityMs,
    required this.equivalentDiameterM,
  });

  final double areaM2;
  final double velocityMs;
  final double equivalentDiameterM;
}

/// Раскладка нагрузок по фазам: что на какой фазе и сколько всего.
class PhaseBalance {
  const PhaseBalance({required this.loads, required this.totals});

  /// Нагрузки каждой фазы в порядке L1, L2, L3.
  final List<List<double>> loads;

  /// Сумма по каждой фазе.
  final List<double> totals;

  /// Перекос: насколько самая нагруженная фаза тяжелее самой лёгкой, в долях
  /// от средней. Ноль — нагрузка разложена поровну.
  double get imbalance {
    final sum = totals.fold<double>(0, (value, item) => value + item);
    if (sum == 0) return 0;
    final average = sum / totals.length;
    final heaviest = totals.reduce((a, b) => a > b ? a : b);
    final lightest = totals.reduce((a, b) => a < b ? a : b);
    return (heaviest - lightest) / average;
  }
}

class EngineeringCalculations {
  const EngineeringCalculations._();

  static AcPowerResult singlePhase({
    required double voltageV,
    required double currentA,
    double powerFactor = 1,
    double efficiency = 1,
  }) {
    positiveValue(voltageV, 'voltageV');
    nonNegativeValue(currentA, 'currentA');
    fractionValue(powerFactor, 'powerFactor');
    fractionValue(efficiency, 'efficiency');
    return AcPowerResult(
      activePowerW: voltageV * currentA * powerFactor * efficiency,
      currentA: currentA,
    );
  }

  static AcPowerResult threePhase({
    required double lineVoltageV,
    required double currentA,
    double powerFactor = 1,
    double efficiency = 1,
  }) {
    positiveValue(lineVoltageV, 'lineVoltageV');
    nonNegativeValue(currentA, 'currentA');
    fractionValue(powerFactor, 'powerFactor');
    fractionValue(efficiency, 'efficiency');
    return AcPowerResult(
      activePowerW:
          math.sqrt(3) * lineVoltageV * currentA * powerFactor * efficiency,
      currentA: currentA,
    );
  }

  static FlowSectionResult circularFlow({
    required double flowM3s,
    required double diameterM,
  }) {
    nonNegativeValue(flowM3s, 'flowM3s');
    positiveValue(diameterM, 'diameterM');
    final area = math.pi * diameterM * diameterM / 4;
    return FlowSectionResult(
      areaM2: area,
      velocityMs: flowM3s / area,
      diameterM: diameterM,
    );
  }

  static double diameterForFlow({
    required double flowM3s,
    required double targetVelocityMs,
  }) {
    nonNegativeValue(flowM3s, 'flowM3s');
    positiveValue(targetVelocityMs, 'targetVelocityMs');
    return math.sqrt(4 * flowM3s / (math.pi * targetVelocityMs));
  }

  static double pipeVolumeM3({
    required double internalDiameterM,
    required double lengthM,
  }) {
    positiveValue(internalDiameterM, 'internalDiameterM');
    nonNegativeValue(lengthM, 'lengthM');
    return math.pi * internalDiameterM * internalDiameterM / 4 * lengthM;
  }

  static double fillTimeSeconds({
    required double volumeM3,
    required double flowM3s,
  }) {
    nonNegativeValue(volumeM3, 'volumeM3');
    positiveValue(flowM3s, 'flowM3s');
    return volumeM3 / flowM3s;
  }

  static double pressureFromWaterHead(double headM) {
    nonNegativeValue(headM, 'headM');
    return 998.2 * 9.80665 * headM;
  }

  static PressureLossResult waterPressureLoss({
    required double flowM3s,
    required double diameterM,
    required double lengthM,
    required double roughnessM,
    double kinematicViscosityM2s = 1.004e-6,
  }) {
    nonNegativeValue(flowM3s, 'flowM3s');
    positiveValue(diameterM, 'diameterM');
    nonNegativeValue(lengthM, 'lengthM');
    nonNegativeValue(roughnessM, 'roughnessM');
    positiveValue(kinematicViscosityM2s, 'kinematicViscosityM2s');
    if (flowM3s == 0) {
      return const PressureLossResult(
        reynolds: 0,
        velocityMs: 0,
        lossPa: 0,
        lossPaPerM: 0,
      );
    }
    final velocity = circularFlow(
      flowM3s: flowM3s,
      diameterM: diameterM,
    ).velocityMs;
    final reynolds = velocity * diameterM / kinematicViscosityM2s;
    final friction = reynolds < 2300
        ? 64 / reynolds
        : 0.25 /
            math.pow(
              math.log(
                    roughnessM / (3.7 * diameterM) +
                        5.74 / math.pow(reynolds, 0.9),
                  ) /
                  math.ln10,
              2,
            );
    final perM = friction / diameterM * 998.2 * velocity * velocity / 2;
    return PressureLossResult(
      reynolds: reynolds,
      velocityMs: velocity,
      lossPa: perM * lengthM,
      lossPaPerM: perM,
    );
  }

  static DuctResult rectangularDuct({
    required double flowM3s,
    required double widthM,
    required double heightM,
  }) {
    nonNegativeValue(flowM3s, 'flowM3s');
    positiveValue(widthM, 'widthM');
    positiveValue(heightM, 'heightM');
    final area = widthM * heightM;
    final equivalent = 1.3 *
        math.pow(widthM * heightM, 0.625) /
        math.pow(widthM + heightM, 0.25);
    return DuctResult(
      areaM2: area,
      velocityMs: flowM3s / area,
      equivalentDiameterM: equivalent,
    );
  }

  static double airFlowForRoom({
    required double lengthM,
    required double widthM,
    required double heightM,
    required double airChangesPerHour,
  }) {
    positiveValue(lengthM, 'lengthM');
    positiveValue(widthM, 'widthM');
    positiveValue(heightM, 'heightM');
    nonNegativeValue(airChangesPerHour, 'airChangesPerHour');
    return lengthM * widthM * heightM * airChangesPerHour;
  }

  /// Раскладка однофазных нагрузок по трём фазам.
  ///
  /// Возвращает не только суммы, но и сами нагрузки на каждой фазе: ответ
  /// «на L3 — 2000 Вт» ничего не говорит монтажнику, а «на L3 — 1200 и 800»
  /// говорит, что именно вешать.
  ///
  /// Нагрузки раскладываются от большей к меньшей, каждая — на самую лёгкую
  /// фазу. Это не идеальное разбиение, но именно так раскидывают руками, и
  /// перекос получается небольшой.
  static PhaseBalance balancePhases(List<double> loadsW) {
    for (final load in loadsW) {
      nonNegativeValue(load, 'load');
    }
    final phases = <List<double>>[[], [], []];
    final totals = [0.0, 0.0, 0.0];
    final sorted = [...loadsW]..sort((a, b) => b.compareTo(a));
    for (final load in sorted) {
      var lightest = 0;
      for (var index = 1; index < totals.length; index++) {
        if (totals[index] < totals[lightest]) lightest = index;
      }
      phases[lightest].add(load);
      totals[lightest] += load;
    }
    return PhaseBalance(
      loads: [for (final phase in phases) List<double>.unmodifiable(phase)],
      totals: List<double>.unmodifiable(totals),
    );
  }
}

/// Расход наружного воздуха по площади помещения, м³/ч.
///
/// Норма на квадратный метр пола зависит от назначения помещения и от того,
/// есть ли естественное проветривание; её значения — в СП 60.13330.2020,
/// приложение В, и вводит их человек.
double airFlowForAreaM3h({
  required double areaM2,
  required double perSquareMetreM3h,
}) {
  nonNegativeValue(areaM2, 'areaM2');
  nonNegativeValue(perSquareMetreM3h, 'perSquareMetreM3h');
  return areaM2 * perSquareMetreM3h;
}

/// Расход наружного воздуха на группу людей, м³/ч.
///
/// Арифметика простая — число людей на норму, — но сама норма зависит от
/// назначения помещения и от того, есть ли естественное проветривание. Её
/// значения приведены в СП 60.13330.2020, приложение В «Минимальный расход
/// наружного воздуха на одного человека», и в приложение вводит человек:
/// подставлять число за него здесь нельзя.
double airFlowForPeopleM3h({
  required double people,
  required double perPersonM3h,
}) {
  nonNegativeValue(people, 'people');
  nonNegativeValue(perPersonM3h, 'perPersonM3h');
  return people * perPersonM3h;
}

/// Стандартный ряд круглых воздуховодов, мм.
///
/// Точный расчётный диаметр не купить: воздуховоды делают по ряду, и в
/// монтаж идёт ближайший больший.
const standardRoundDuctsMm = <double>[
  100,
  125,
  160,
  200,
  250,
  315,
  400,
  500,
  630,
  800,
];

/// Ближайший воздуховод из ряда, не меньше расчётного диаметра.
///
/// `null` — расчётный диаметр вышел за ряд: такой воздуховод подбирают по
/// каталогу изготовителя, а не округлением.
double? roundDuctForDiameter(double diameterMm) {
  nonNegativeValue(diameterMm, 'diameterMm');
  for (final size in standardRoundDuctsMm) {
    if (size >= diameterMm) return size;
  }
  return null;
}

/// Тепловая мощность потока воды, Вт.
///
/// `Q = ρ · c · V · ΔT`. Плотность 998,2 кг/м³ и теплоёмкость 4187 Дж/(кг·К)
/// взяты для воды около 20 °C: при других температурах они меняются на
/// единицы процентов.
double waterHeatPowerW({
  required double flowM3s,
  required double deltaTemperatureK,
}) {
  nonNegativeValue(flowM3s, 'flowM3s');
  nonNegativeValue(deltaTemperatureK, 'deltaTemperatureK');
  return 998.2 * 4187 * flowM3s * deltaTemperatureK;
}

/// Расход воды, который переносит заданную мощность, м³/с.
double waterFlowForHeatM3s({
  required double powerW,
  required double deltaTemperatureK,
}) {
  nonNegativeValue(powerW, 'powerW');
  positiveValue(deltaTemperatureK, 'deltaTemperatureK');
  return powerW / (998.2 * 4187 * deltaTemperatureK);
}

/// Мощность нагрева приточного воздуха, Вт.
///
/// `P = ρ · c · L · ΔT` при плотности 1,2 кг/м³ и теплоёмкости
/// 1005 Дж/(кг·К) — воздух около 20 °C.
double airHeatPowerW({
  required double flowM3s,
  required double deltaTemperatureK,
}) {
  nonNegativeValue(flowM3s, 'flowM3s');
  nonNegativeValue(deltaTemperatureK, 'deltaTemperatureK');
  return 1.2 * 1005 * flowM3s * deltaTemperatureK;
}

/// Перепад высоты на участке с заданным уклоном, м.
///
/// Уклон задают долей: 0,02 — это два сантиметра на метр.
double slopeFallM({required double slope, required double lengthM}) {
  nonNegativeValue(slope, 'slope');
  nonNegativeValue(lengthM, 'lengthM');
  return slope * lengthM;
}

/// Уклон участка по перепаду и длине.
double slopeFromFall({required double fallM, required double lengthM}) {
  nonNegativeValue(fallM, 'fallM');
  positiveValue(lengthM, 'lengthM');
  return fallM / lengthM;
}
