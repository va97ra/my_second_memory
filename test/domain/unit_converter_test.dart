import 'dart:math' as math;

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

double _convert(UnitCategory category, String from, String to, double value) =>
    UnitConverter.convert(
      category: category,
      fromUnitId: from,
      toUnitId: to,
      value: value,
    );

void main() {
  test('converts engineering units through the category base unit', () {
    expect(_convert(UnitCategory.flow, 'm3_h', 'l_s', 3.6), closeTo(1, 1e-10));
    expect(
        _convert(UnitCategory.pressure, 'bar', 'kpa', 1), closeTo(100, 1e-10));
  });

  test('temperature conversion is affine and reversible', () {
    final fahrenheit =
        _convert(UnitCategory.temperature, 'celsius', 'fahrenheit', 100);
    expect(fahrenheit, closeTo(212, 1e-10));
    expect(
      _convert(UnitCategory.temperature, 'fahrenheit', 'celsius', fahrenheit),
      closeTo(100, 1e-10),
    );
  });

  test('rejects unknown units and non-finite values', () {
    expect(
      () => _convert(UnitCategory.length, 'unknown', 'm', 1),
      throwsArgumentError,
    );
    expect(
      () => _convert(UnitCategory.length, 'm', 'km', double.infinity),
      throwsArgumentError,
    );
  });

  test('unitOrNull answers instead of throwing', () {
    expect(UnitConverter.unitOrNull(UnitCategory.length, 'm')?.symbol, 'м');
    expect(UnitConverter.unitOrNull(UnitCategory.length, 'wire_area'), isNull);
  });

  // Множители — определения, а не округления из чужой таблицы: каждое из этих
  // равенств можно проверить на бумаге.
  test('imperial units keep their defining factors', () {
    // Множитель собран из определений (дюйм → фут → ярд → миля), и последний
    // бит двоичной дроби на этом пути теряется: сравнение — с допуском.
    expect(
        _convert(UnitCategory.length, 'mile', 'm', 1), closeTo(1609.344, 1e-9));
    expect(
        _convert(UnitCategory.length, 'yard', 'inch', 1), closeTo(36, 1e-10));
    expect(_convert(UnitCategory.mass, 'lb', 'oz', 1), closeTo(16, 1e-10));
    expect(
      _convert(UnitCategory.area, 'acre', 'm2', 1),
      closeTo(4046.8564224, 1e-6),
    );
    expect(
      _convert(UnitCategory.volume, 'barrel_oil', 'gallon_us', 1),
      closeTo(42, 1e-10),
    );
  });

  test('force-based units follow standard gravity', () {
    expect(
      _convert(UnitCategory.pressure, 'kgf_cm2', 'pa', 1),
      closeTo(98066.5, 1e-9),
    );
    expect(
      _convert(UnitCategory.pressure, 'psi', 'pa', 1),
      closeTo(6894.757293168361, 1e-9),
    );
    expect(_convert(UnitCategory.torque, 'kgf_m', 'n_m', 1),
        closeTo(9.80665, 1e-12));
    expect(
      _convert(UnitCategory.power, 'hp_metric', 'w', 1),
      closeTo(735.49875, 1e-9),
    );
  });

  test('angles and time run on their own base', () {
    expect(
      _convert(UnitCategory.angle, 'degree', 'radian', 180),
      closeTo(math.pi, 1e-12),
    );
    expect(
      _convert(UnitCategory.angle, 'turn', 'degree', 1),
      closeTo(360, 1e-10),
    );
    expect(_convert(UnitCategory.time, 'day', 'h', 1), closeTo(24, 1e-10));
    expect(
      _convert(UnitCategory.frequency, 'rpm', 'hz', 60),
      closeTo(1, 1e-10),
    );
  });

  test('дюйм дробью — тот же дюйм, только читается иначе', () {
    expect(
      _convert(UnitCategory.length, 'inch_fraction', 'mm', 0.75),
      closeTo(19.05, 1e-10),
    );
    expect(
      UnitConverter.unitOrNull(UnitCategory.length, 'inch_fraction')?.display,
      UnitDisplay.inchFraction,
    );
    expect(
      UnitConverter.unitOrNull(UnitCategory.length, 'inch')?.display,
      UnitDisplay.decimal,
    );
  });

  // Ключ единицы уходит в сохранённый расчёт и в резервную копию. Единицу
  // можно добавить, но переименование ключа рвёт чужие сохранённые записи.
  test('keys that saved calculations rely on stay in the table', () {
    const legacy = {
      UnitCategory.length: ['mm', 'cm', 'm', 'km', 'inch', 'foot'],
      UnitCategory.area: ['mm2', 'cm2', 'm2', 'ha', 'km2'],
      UnitCategory.volume: ['ml', 'l', 'm3', 'cm3', 'gallon_us'],
      UnitCategory.mass: ['g', 'kg', 't', 'lb'],
      UnitCategory.temperature: ['celsius', 'kelvin', 'fahrenheit'],
      UnitCategory.pressure: [
        'pa',
        'kpa',
        'mpa',
        'bar',
        'atm',
        'mmhg',
        'm_h2o',
      ],
      UnitCategory.speed: ['m_s', 'km_h', 'ft_s'],
      UnitCategory.flow: ['m3_s', 'm3_h', 'l_s', 'l_min'],
      UnitCategory.power: ['w', 'kw', 'mw', 'hp_metric'],
      UnitCategory.energy: ['j', 'kj', 'wh', 'kwh'],
      UnitCategory.data: ['byte', 'kb', 'mb', 'gb', 'tb'],
      UnitCategory.voltage: ['mv', 'v', 'kv'],
      UnitCategory.current: ['ma', 'a', 'ka'],
      UnitCategory.resistance: ['mohm', 'ohm', 'kohm', 'megohm'],
      UnitCategory.frequency: ['hz', 'khz', 'mhz'],
    };
    for (final entry in legacy.entries) {
      for (final id in entry.value) {
        expect(
          UnitConverter.unitOrNull(entry.key, id),
          isNotNull,
          reason: '${entry.key.name}/$id',
        );
      }
    }
  });

  test('every unit id is unique inside its category', () {
    for (final entry in UnitConverter.units.entries) {
      final ids = entry.value.map((unit) => unit.id).toSet();
      expect(ids.length, entry.value.length, reason: entry.key.name);
    }
  });
}
