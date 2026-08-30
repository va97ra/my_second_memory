import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts engineering units through the category base unit', () {
    expect(
      UnitConverter.convert(
        category: UnitCategory.flow,
        fromUnitId: 'm3_h',
        toUnitId: 'l_s',
        value: 3.6,
      ),
      closeTo(1, 1e-10),
    );
    expect(
      UnitConverter.convert(
        category: UnitCategory.pressure,
        fromUnitId: 'bar',
        toUnitId: 'kpa',
        value: 1,
      ),
      closeTo(100, 1e-10),
    );
  });

  test('temperature conversion is affine and reversible', () {
    final fahrenheit = UnitConverter.convert(
      category: UnitCategory.temperature,
      fromUnitId: 'celsius',
      toUnitId: 'fahrenheit',
      value: 100,
    );
    expect(fahrenheit, closeTo(212, 1e-10));
    expect(
      UnitConverter.convert(
        category: UnitCategory.temperature,
        fromUnitId: 'fahrenheit',
        toUnitId: 'celsius',
        value: fahrenheit,
      ),
      closeTo(100, 1e-10),
    );
  });

  test('rejects unknown units and non-finite values', () {
    expect(
      () => UnitConverter.convert(
        category: UnitCategory.length,
        fromUnitId: 'unknown',
        toUnitId: 'm',
        value: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => UnitConverter.convert(
        category: UnitCategory.length,
        fromUnitId: 'm',
        toUnitId: 'km',
        value: double.infinity,
      ),
      throwsArgumentError,
    );
  });
}
