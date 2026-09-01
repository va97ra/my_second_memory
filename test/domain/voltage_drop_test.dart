import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('падение напряжения', () {
    VoltageDropResult copperLine({
      bool threePhase = false,
      double sectionMm2 = 2.5,
      double powerFactor = 0.9,
    }) =>
        voltageDrop(
          currentA: 10,
          oneWayLengthM: 20,
          sectionMm2: sectionMm2,
          voltageV: 230,
          threePhase: threePhase,
          material: ConductorMaterial.copper,
          routing: WireRouting.conduitTwo,
          powerFactor: powerFactor,
        );

    test('холодная жила: активная и реактивная составляющие', () {
      final cold = copperLine().cold;
      // R = 0,0175 · 20 / 2,5 = 0,14 Ом; X = 0,08 · 20 / 1000 = 0,0016 Ом.
      expect(cold.temperatureC, coldConductorTemperatureC);
      expect(cold.resistanceOhm, closeTo(0.14, 1e-9));
      expect(cold.reactanceOhm, closeTo(0.0016, 1e-9));
      expect(cold.dropV, closeTo(2.533949, 1e-5));
      expect(cold.dropPercent, closeTo(1.101717, 1e-5));
    });

    test('нагрев жилы поднимает сопротивление и падение', () {
      final result = copperLine();
      expect(result.hot.temperatureC, hotConductorTemperatureC);
      // 0,0175 · (1 + 0,00393 · 50) = 0,02093875 Ом·мм²/м.
      expect(result.hot.resistanceOhm, closeTo(0.16751, 1e-5));
      expect(result.hot.dropV, closeTo(3.029128, 1e-5));
      expect(result.hot.dropV, greaterThan(result.cold.dropV));
    });

    test('потери считаются от полного тока, а не от активной части', () {
      // Однофазная линия: две жилы под током, 2 · I² · R.
      expect(copperLine().cold.lossW, closeTo(28, 1e-9));
      // Трёхфазная: три жилы, 3 · I² · R — не √3, как было раньше.
      expect(
        copperLine(threePhase: true).cold.lossW,
        closeTo(42, 1e-9),
      );
    });

    test('cos φ = 1 оставляет только активную составляющую', () {
      final cold = copperLine(powerFactor: 1).cold;
      expect(cold.dropV, closeTo(2 * 10 * 0.14, 1e-9));
    });

    test('норма выполняется или нет по нагретой жиле', () {
      final result = copperLine();
      expect(result.withinLimit(5), isTrue);
      expect(result.withinLimit(1), isFalse);
    });
  });

  group('подбор сечения по норме падения', () {
    double? minimumFor(double limitPercent) => minimumSectionForDrop(
          currentA: 10,
          oneWayLengthM: 20,
          voltageV: 230,
          threePhase: false,
          material: ConductorMaterial.copper,
          routing: WireRouting.conduitTwo,
          limitPercent: limitPercent,
          powerFactor: 0.9,
        );

    test('берёт первое сечение из ряда, которое проходит', () {
      expect(minimumFor(5), 1.5);
      expect(minimumFor(1), 4);
    });

    test('за пределами ряда ответа нет', () {
      expect(minimumFor(0.01), isNull);
    });
  });

  group('границы', () {
    test('нулевое сечение и отрицательная длина отвергаются', () {
      expect(
        () => voltageDrop(
          currentA: 10,
          oneWayLengthM: 20,
          sectionMm2: 0,
          voltageV: 230,
          threePhase: false,
          material: ConductorMaterial.copper,
          routing: WireRouting.conduitTwo,
        ),
        throwsArgumentError,
      );
      expect(
        () => voltageDrop(
          currentA: 10,
          oneWayLengthM: -1,
          sectionMm2: 2.5,
          voltageV: 230,
          threePhase: false,
          material: ConductorMaterial.copper,
          routing: WireRouting.conduitTwo,
        ),
        throwsArgumentError,
      );
    });

    test('алюминий сопротивляется сильнее меди', () {
      double dropFor(ConductorMaterial material) => voltageDrop(
            currentA: 10,
            oneWayLengthM: 20,
            sectionMm2: 2.5,
            voltageV: 230,
            threePhase: false,
            material: material,
            routing: WireRouting.conduitTwo,
          ).hot.dropV;
      expect(
        dropFor(ConductorMaterial.aluminium),
        greaterThan(dropFor(ConductorMaterial.copper)),
      );
    });
  });
}
