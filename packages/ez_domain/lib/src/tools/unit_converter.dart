import 'dart:math' as math;

enum UnitCategory {
  length,
  area,
  volume,
  mass,
  temperature,
  pressure,
  speed,
  flow,
  power,
  energy,
  data,
}

class UnitDefinition {
  const UnitDefinition({
    required this.id,
    required this.symbol,
    required this.toBase,
    required this.fromBase,
  });

  final String id;
  final String symbol;
  final double Function(double value) toBase;
  final double Function(double value) fromBase;

  factory UnitDefinition.linear(String id, String symbol, double factor) {
    return UnitDefinition(
      id: id,
      symbol: symbol,
      toBase: (value) => value * factor,
      fromBase: (value) => value / factor,
    );
  }
}

class UnitConverter {
  const UnitConverter._();

  static final Map<UnitCategory, List<UnitDefinition>> units = {
    UnitCategory.length: [
      UnitDefinition.linear('mm', 'мм', 0.001),
      UnitDefinition.linear('cm', 'см', 0.01),
      UnitDefinition.linear('m', 'м', 1),
      UnitDefinition.linear('km', 'км', 1000),
      UnitDefinition.linear('inch', 'дюйм', 0.0254),
      UnitDefinition.linear('foot', 'фут', 0.3048),
    ],
    UnitCategory.area: [
      UnitDefinition.linear('mm2', 'мм²', 1e-6),
      UnitDefinition.linear('cm2', 'см²', 1e-4),
      UnitDefinition.linear('m2', 'м²', 1),
      UnitDefinition.linear('ha', 'га', 10000),
      UnitDefinition.linear('km2', 'км²', 1e6),
    ],
    UnitCategory.volume: [
      UnitDefinition.linear('ml', 'мл', 1e-6),
      UnitDefinition.linear('l', 'л', 0.001),
      UnitDefinition.linear('m3', 'м³', 1),
      UnitDefinition.linear('cm3', 'см³', 1e-6),
      UnitDefinition.linear('gallon_us', 'гал US', 0.003785411784),
    ],
    UnitCategory.mass: [
      UnitDefinition.linear('g', 'г', 0.001),
      UnitDefinition.linear('kg', 'кг', 1),
      UnitDefinition.linear('t', 'т', 1000),
      UnitDefinition.linear('lb', 'фунт', 0.45359237),
    ],
    UnitCategory.temperature: [
      UnitDefinition(
        id: 'celsius',
        symbol: '°C',
        toBase: (value) => value + 273.15,
        fromBase: (value) => value - 273.15,
      ),
      UnitDefinition.linear('kelvin', 'K', 1),
      UnitDefinition(
        id: 'fahrenheit',
        symbol: '°F',
        toBase: (value) => (value - 32) * 5 / 9 + 273.15,
        fromBase: (value) => (value - 273.15) * 9 / 5 + 32,
      ),
    ],
    UnitCategory.pressure: [
      UnitDefinition.linear('pa', 'Па', 1),
      UnitDefinition.linear('kpa', 'кПа', 1000),
      UnitDefinition.linear('mpa', 'МПа', 1e6),
      UnitDefinition.linear('bar', 'бар', 100000),
      UnitDefinition.linear('atm', 'атм', 101325),
      UnitDefinition.linear('mmhg', 'мм рт. ст.', 133.322387415),
      UnitDefinition.linear('m_h2o', 'м вод. ст.', 9806.65),
    ],
    UnitCategory.speed: [
      UnitDefinition.linear('m_s', 'м/с', 1),
      UnitDefinition.linear('km_h', 'км/ч', 1 / 3.6),
      UnitDefinition.linear('ft_s', 'фут/с', 0.3048),
    ],
    UnitCategory.flow: [
      UnitDefinition.linear('m3_s', 'м³/с', 1),
      UnitDefinition.linear('m3_h', 'м³/ч', 1 / 3600),
      UnitDefinition.linear('l_s', 'л/с', 0.001),
      UnitDefinition.linear('l_min', 'л/мин', 0.001 / 60),
    ],
    UnitCategory.power: [
      UnitDefinition.linear('w', 'Вт', 1),
      UnitDefinition.linear('kw', 'кВт', 1000),
      UnitDefinition.linear('mw', 'МВт', 1e6),
      UnitDefinition.linear('hp_metric', 'л.с.', 735.49875),
    ],
    UnitCategory.energy: [
      UnitDefinition.linear('j', 'Дж', 1),
      UnitDefinition.linear('kj', 'кДж', 1000),
      UnitDefinition.linear('wh', 'Вт·ч', 3600),
      UnitDefinition.linear('kwh', 'кВт·ч', 3.6e6),
    ],
    UnitCategory.data: [
      UnitDefinition.linear('byte', 'Б', 1),
      UnitDefinition.linear('kb', 'КБ', 1024),
      UnitDefinition.linear('mb', 'МБ', math.pow(1024, 2).toDouble()),
      UnitDefinition.linear('gb', 'ГБ', math.pow(1024, 3).toDouble()),
      UnitDefinition.linear('tb', 'ТБ', math.pow(1024, 4).toDouble()),
    ],
  };

  static double convert({
    required UnitCategory category,
    required String fromUnitId,
    required String toUnitId,
    required double value,
  }) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Value must be finite');
    }
    final categoryUnits = units[category]!;
    final from = categoryUnits.firstWhere(
      (unit) => unit.id == fromUnitId,
      orElse: () => throw ArgumentError.value(fromUnitId, 'fromUnitId'),
    );
    final to = categoryUnits.firstWhere(
      (unit) => unit.id == toUnitId,
      orElse: () => throw ArgumentError.value(toUnitId, 'toUnitId'),
    );
    final result = to.fromBase(from.toBase(value));
    if (!result.isFinite) {
      throw StateError('Conversion produced a non-finite result');
    }
    return result;
  }
}
