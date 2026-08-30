import 'dart:math' as math;

class AcPowerResult {
  const AcPowerResult({required this.activePowerW, required this.currentA});

  final double activePowerW;
  final double currentA;
}

class VoltageDropResult {
  const VoltageDropResult({
    required this.dropV,
    required this.dropPercent,
    required this.lossW,
  });

  final double dropV;
  final double dropPercent;
  final double lossW;
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

class EngineeringCalculations {
  const EngineeringCalculations._();

  static AcPowerResult singlePhase({
    required double voltageV,
    required double currentA,
    double powerFactor = 1,
    double efficiency = 1,
  }) {
    _positive(voltageV, 'voltageV');
    _nonNegative(currentA, 'currentA');
    _fraction(powerFactor, 'powerFactor');
    _fraction(efficiency, 'efficiency');
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
    _positive(lineVoltageV, 'lineVoltageV');
    _nonNegative(currentA, 'currentA');
    _fraction(powerFactor, 'powerFactor');
    _fraction(efficiency, 'efficiency');
    return AcPowerResult(
      activePowerW:
          math.sqrt(3) * lineVoltageV * currentA * powerFactor * efficiency,
      currentA: currentA,
    );
  }

  static double currentForPower({
    required double powerW,
    required double voltageV,
    required bool threePhase,
    double powerFactor = 1,
    double efficiency = 1,
  }) {
    _nonNegative(powerW, 'powerW');
    _positive(voltageV, 'voltageV');
    _fraction(powerFactor, 'powerFactor');
    _fraction(efficiency, 'efficiency');
    final phaseFactor = threePhase ? math.sqrt(3) : 1;
    return powerW / (phaseFactor * voltageV * powerFactor * efficiency);
  }

  static VoltageDropResult voltageDrop({
    required double currentA,
    required double oneWayLengthM,
    required double sectionMm2,
    required double voltageV,
    required bool threePhase,
    required bool copper,
    double powerFactor = 1,
  }) {
    _nonNegative(currentA, 'currentA');
    _nonNegative(oneWayLengthM, 'oneWayLengthM');
    _positive(sectionMm2, 'sectionMm2');
    _positive(voltageV, 'voltageV');
    _fraction(powerFactor, 'powerFactor');
    final resistivity = copper ? 0.0175 : 0.0282;
    final lengthFactor = threePhase ? math.sqrt(3) : 2;
    final resistance = lengthFactor * resistivity * oneWayLengthM / sectionMm2;
    final drop = currentA * resistance * powerFactor;
    return VoltageDropResult(
      dropV: drop,
      dropPercent: drop / voltageV * 100,
      lossW: currentA * currentA * resistance,
    );
  }

  static FlowSectionResult circularFlow({
    required double flowM3s,
    required double diameterM,
  }) {
    _nonNegative(flowM3s, 'flowM3s');
    _positive(diameterM, 'diameterM');
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
    _nonNegative(flowM3s, 'flowM3s');
    _positive(targetVelocityMs, 'targetVelocityMs');
    return math.sqrt(4 * flowM3s / (math.pi * targetVelocityMs));
  }

  static double pipeVolumeM3({
    required double internalDiameterM,
    required double lengthM,
  }) {
    _positive(internalDiameterM, 'internalDiameterM');
    _nonNegative(lengthM, 'lengthM');
    return math.pi * internalDiameterM * internalDiameterM / 4 * lengthM;
  }

  static double fillTimeSeconds({
    required double volumeM3,
    required double flowM3s,
  }) {
    _nonNegative(volumeM3, 'volumeM3');
    _positive(flowM3s, 'flowM3s');
    return volumeM3 / flowM3s;
  }

  static double pressureFromWaterHead(double headM) {
    _nonNegative(headM, 'headM');
    return 998.2 * 9.80665 * headM;
  }

  static PressureLossResult waterPressureLoss({
    required double flowM3s,
    required double diameterM,
    required double lengthM,
    required double roughnessM,
    double kinematicViscosityM2s = 1.004e-6,
  }) {
    _nonNegative(flowM3s, 'flowM3s');
    _positive(diameterM, 'diameterM');
    _nonNegative(lengthM, 'lengthM');
    _nonNegative(roughnessM, 'roughnessM');
    _positive(kinematicViscosityM2s, 'kinematicViscosityM2s');
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
    _nonNegative(flowM3s, 'flowM3s');
    _positive(widthM, 'widthM');
    _positive(heightM, 'heightM');
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
    _positive(lengthM, 'lengthM');
    _positive(widthM, 'widthM');
    _positive(heightM, 'heightM');
    _nonNegative(airChangesPerHour, 'airChangesPerHour');
    return lengthM * widthM * heightM * airChangesPerHour;
  }

  static List<double> balancePhases(List<double> loadsW) {
    for (final load in loadsW) {
      _nonNegative(load, 'load');
    }
    final phases = [0.0, 0.0, 0.0];
    final sorted = [...loadsW]..sort((a, b) => b.compareTo(a));
    for (final load in sorted) {
      var lightest = 0;
      for (var index = 1; index < phases.length; index++) {
        if (phases[index] < phases[lightest]) lightest = index;
      }
      phases[lightest] += load;
    }
    return phases;
  }

  static void _positive(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
          value, name, 'Must be finite and greater than 0');
    }
  }

  static void _nonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, name, 'Must be finite and non-negative');
    }
  }

  static void _fraction(double value, String name) {
    if (!value.isFinite || value <= 0 || value > 1) {
      throw ArgumentError.value(value, name, 'Must be in the range (0, 1]');
    }
  }
}
