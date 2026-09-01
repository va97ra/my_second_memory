import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('круглый воздуховод из ряда', () {
    test('берётся ближайший больший, а не округлённый', () {
      expect(roundDuctForDiameter(242.8), 250);
      expect(roundDuctForDiameter(250), 250);
      expect(roundDuctForDiameter(251), 315);
    });

    test('за пределами ряда ответа нет', () {
      expect(roundDuctForDiameter(900), isNull);
    });
  });

  group('тепло, перенесённое потоком', () {
    test('вода: мощность и обратный расчёт расхода сходятся', () {
      // 0,5 м³/ч при перепаде 20 К.
      const flow = 0.5 / 3600;
      final power = waterHeatPowerW(flowM3s: flow, deltaTemperatureK: 20);
      expect(power, closeTo(11610, 10));
      expect(
        waterFlowForHeatM3s(powerW: power, deltaTemperatureK: 20),
        closeTo(flow, 1e-12),
      );
    });

    test('воздух: 500 м³/ч на 20 К требуют около 3,3 кВт', () {
      final power = airHeatPowerW(
        flowM3s: 500 / 3600,
        deltaTemperatureK: 20,
      );
      expect(power, closeTo(3350, 10));
    });

    test('нулевой перепад в обратном расчёте отвергается', () {
      expect(
        () => waterFlowForHeatM3s(powerW: 1000, deltaTemperatureK: 0),
        throwsArgumentError,
      );
    });
  });

  group('расход по людям', () {
    test('число людей на норму', () {
      expect(
        airFlowForPeopleM3h(people: 4, perPersonM3h: 60),
        closeTo(240, 1e-12),
      );
    });

    test('отрицательное число людей отвергается', () {
      expect(
        () => airFlowForPeopleM3h(people: -1, perPersonM3h: 60),
        throwsArgumentError,
      );
    });
  });

  group('уклон', () {
    test('перепад и уклон обратны друг другу', () {
      expect(slopeFallM(slope: 0.02, lengthM: 12), closeTo(0.24, 1e-12));
      expect(slopeFromFall(fallM: 0.24, lengthM: 12), closeTo(0.02, 1e-12));
    });

    test('нулевая длина не даёт уклона', () {
      expect(
        () => slopeFromFall(fallM: 0.2, lengthM: 0),
        throwsArgumentError,
      );
    });
  });
}
