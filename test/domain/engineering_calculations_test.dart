import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates single and three phase active power', () {
    expect(
      EngineeringCalculations.singlePhase(
        voltageV: 230,
        currentA: 10,
        powerFactor: 0.8,
      ).activePowerW,
      closeTo(1840, 1e-9),
    );
    expect(
      EngineeringCalculations.threePhase(
        lineVoltageV: 400,
        currentA: 10,
        powerFactor: 0.8,
      ).activePowerW,
      closeTo(5542.56, 0.01),
    );
  });

  test('calculates copper single phase voltage drop', () {
    final result = EngineeringCalculations.voltageDrop(
      currentA: 10,
      oneWayLengthM: 20,
      sectionMm2: 2.5,
      voltageV: 230,
      threePhase: false,
      copper: true,
    );
    expect(result.dropV, closeTo(2.8, 1e-9));
    expect(result.dropPercent, closeTo(1.21739, 1e-5));
  });

  test('calculates pipe flow and room air exchange', () {
    final flow = EngineeringCalculations.circularFlow(
      flowM3s: 0.001,
      diameterM: 0.05,
    );
    expect(flow.velocityMs, closeTo(0.5093, 0.0001));
    expect(
      EngineeringCalculations.airFlowForRoom(
        lengthM: 5,
        widthM: 4,
        heightM: 3,
        airChangesPerHour: 2,
      ),
      120,
    );
  });

  test('rejects physically invalid inputs', () {
    expect(
      () => EngineeringCalculations.circularFlow(
        flowM3s: 1,
        diameterM: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => EngineeringCalculations.singlePhase(
        voltageV: 230,
        currentA: 10,
        powerFactor: 1.1,
      ),
      throwsArgumentError,
    );
  });

  test('uses Darcy-Weisbach loss and accepts zero flow', () {
    final result = EngineeringCalculations.waterPressureLoss(
      flowM3s: 0.001,
      diameterM: 0.05,
      lengthM: 10,
      roughnessM: 0.00001,
    );
    expect(result.reynolds, closeTo(25365, 2));
    expect(result.lossPaPerM, closeTo(64.46, 0.1));
    expect(result.lossPa, closeTo(644.6, 1));

    final stopped = EngineeringCalculations.waterPressureLoss(
      flowM3s: 0,
      diameterM: 0.05,
      lengthM: 10,
      roughnessM: 0.00001,
    );
    expect(stopped.lossPa, 0);
  });

  test('calculates pipe volume, fill time and equivalent duct diameter', () {
    final volume = EngineeringCalculations.pipeVolumeM3(
      internalDiameterM: 0.1,
      lengthM: 10,
    );
    expect(volume, closeTo(0.0785398, 1e-7));
    expect(
      EngineeringCalculations.fillTimeSeconds(
        volumeM3: volume,
        flowM3s: 0.001,
      ),
      closeTo(78.5398, 1e-4),
    );
    final duct = EngineeringCalculations.rectangularDuct(
      flowM3s: 1000 / 3600,
      widthM: 0.4,
      heightM: 0.2,
    );
    expect(duct.velocityMs, closeTo(3.4722, 1e-4));
    expect(duct.equivalentDiameterM, closeTo(0.304, 0.002));
  });

  test('rejects non-finite and extreme overflow inputs', () {
    expect(
      () => EngineeringCalculations.singlePhase(
        voltageV: double.infinity,
        currentA: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => EngineeringCalculations.diameterForFlow(
        flowM3s: -1,
        targetVelocityMs: 1,
      ),
      throwsArgumentError,
    );
  });
}
