import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the smallest section that carries the load is chosen', () {
    final result = selectWireSection(currentA: 20)!;

    // 2,5 мм² в трубе на три жилы держат 25 А, 1,5 мм² — только 17 А.
    expect(result.sectionMm2, 2.5);
    expect(result.allowableCurrentA, 25);
  });

  test('a tighter routing forces a thicker wire at the same load', () {
    final open = selectWireSection(
      currentA: 45,
      routing: WireRouting.openAir,
    )!;
    final conduit = selectWireSection(
      currentA: 45,
      routing: WireRouting.conduitThree,
    )!;

    expect(open.sectionMm2, 6);
    expect(conduit.sectionMm2, 10);
  });

  test('aluminium needs more copper than copper for the same load', () {
    final copper = selectWireSection(currentA: 60)!;
    final aluminium = selectWireSection(
      currentA: 60,
      material: ConductorMaterial.aluminium,
    )!;

    expect(copper.sectionMm2, lessThan(aluminium.sectionMm2));
  });

  test('a load beyond the table answers nothing instead of the thickest wire',
      () {
    expect(selectWireSection(currentA: 400), isNull);
  });

  test('the breaker never exceeds what the wire carries', () {
    final result = selectWireSection(currentA: 30)!;

    // 4 мм² в трубе на три жилы держат 35 А, ближайший номинал не ниже 30 —
    // 32 А, и он укладывается в эти 35.
    expect(result.sectionMm2, 4);
    expect(result.allowableCurrentA, 35);
    expect(result.breakerA, 32);
    expect(result.breakerA! <= result.allowableCurrentA, isTrue);
  });

  test('a thin margin is reported, not rounded away', () {
    // 1,5 мм² в трубе на три жилы таблица оценивает в 17 А, поэтому под 16 А
    // они формально проходят — с запасом всего в 6 процентов. Ответ обязан
    // показать этот запас, а не молча выдать сечение как достаточное:
    // решение о переходе на 2,5 мм² принимает человек, а не таблица.
    final result = selectWireSection(currentA: 16)!;

    expect(result.sectionMm2, 1.5);
    expect(result.allowableCurrentA, 17);
    expect(result.margin, closeTo(1.06, 0.01));
  });

  test('current follows from the load and the number of phases', () {
    expect(
      singlePhaseCurrent(powerW: 2300, voltageV: 230),
      closeTo(10, 0.001),
    );
    expect(
      threePhaseCurrent(powerW: 6928, lineVoltageV: 400),
      closeTo(10, 0.01),
    );
  });

  test('a negative load is refused rather than sized', () {
    expect(() => selectWireSection(currentA: -1), throwsArgumentError);
    expect(
      () => singlePhaseCurrent(powerW: 100, voltageV: 0),
      throwsArgumentError,
    );
  });
}
