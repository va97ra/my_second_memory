import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('напряжение по току и сопротивлению', () {
    final result = solveOhmLaw(
      unknown: OhmLawUnknown.voltage,
      currentA: 5,
      resistanceOhm: 46,
    );
    expect(result.voltageV, closeTo(230, 1e-9));
    expect(result.value, result.voltageV);
    // Пример из задания: 230 В при 5 А дают 1150 Вт.
    expect(result.powerW, closeTo(1150, 1e-9));
  });

  test('ток по напряжению и сопротивлению', () {
    final result = solveOhmLaw(
      unknown: OhmLawUnknown.current,
      voltageV: 230,
      resistanceOhm: 46,
    );
    expect(result.currentA, closeTo(5, 1e-9));
    expect(result.powerW, closeTo(1150, 1e-9));
  });

  test('сопротивление по напряжению и току', () {
    final result = solveOhmLaw(
      unknown: OhmLawUnknown.resistance,
      voltageV: 230,
      currentA: 5,
    );
    expect(result.resistanceOhm, closeTo(46, 1e-9));
    expect(result.value, result.resistanceOhm);
  });

  test('деления на ноль не происходит — расчёт отказывается считать', () {
    expect(
      () => solveOhmLaw(
        unknown: OhmLawUnknown.current,
        voltageV: 230,
        resistanceOhm: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => solveOhmLaw(
        unknown: OhmLawUnknown.resistance,
        voltageV: 230,
        currentA: 0,
      ),
      throwsArgumentError,
    );
  });

  test('недостающее значение — ошибка, а не подстановка нуля', () {
    expect(
      () => solveOhmLaw(unknown: OhmLawUnknown.voltage, currentA: 5),
      throwsArgumentError,
    );
  });
}
