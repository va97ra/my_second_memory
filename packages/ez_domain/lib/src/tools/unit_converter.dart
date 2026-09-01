/// Перевод величин: таблица единиц и пересчёт через базовую единицу.
///
/// Множители здесь — определения, а не нормативы: дюйм равен 0.0254 м по
/// договору, и это проверяется арифметикой. Всё, что выведено из другого
/// множителя, записано выражением — чтобы опечатку в последней цифре нельзя
/// было внести незаметно.
library;

import 'dart:math' as math;

enum UnitCategory {
  length,
  area,
  volume,
  mass,
  density,
  temperature,
  pressure,
  speed,
  flow,
  power,
  energy,
  torque,
  time,
  angle,
  data,
  voltage,
  current,
  resistance,
  frequency,
}

/// Как читается число этой единицы.
///
/// Правило принадлежит единице, а не экрану: сантехнику дюйм нужен дробью
/// («три четверти»), и это свойство самого дюйма. Рисует дробь интерфейс,
/// но решает — таблица.
enum UnitDisplay { decimal, inchFraction }

class UnitDefinition {
  const UnitDefinition({
    required this.id,
    required this.symbol,
    required this.toBase,
    required this.fromBase,
    this.display = UnitDisplay.decimal,
  });

  /// Ключ, под которым единица уходит в сохранённый расчёт.
  ///
  /// Переименование ключа ломает сохранённые расчёты и резервные копии:
  /// в таблицу единицы добавляют, а старые не трогают.
  final String id;
  final String symbol;
  final double Function(double value) toBase;
  final double Function(double value) fromBase;
  final UnitDisplay display;

  factory UnitDefinition.linear(
    String id,
    String symbol,
    double factor, {
    UnitDisplay display = UnitDisplay.decimal,
  }) {
    return UnitDefinition(
      id: id,
      symbol: symbol,
      toBase: (value) => value * factor,
      fromBase: (value) => value / factor,
      display: display,
    );
  }
}

// Определения, из которых выведено остальное. Дюйм, фунт и стандартное
// ускорение свободного падения — точные значения по определению.
const double _inch = 0.0254;
const double _foot = _inch * 12;
const double _yard = _foot * 3;
const double _mile = _yard * 1760;
const double _pound = 0.45359237;
const double _gravity = 9.80665;
const double _poundForce = _pound * _gravity;
const double _gallonUs = 231 * _inch * _inch * _inch;

class UnitConverter {
  const UnitConverter._();

  static final Map<UnitCategory, List<UnitDefinition>> units = {
    UnitCategory.length: [
      UnitDefinition.linear('mm', 'мм', 0.001),
      UnitDefinition.linear('cm', 'см', 0.01),
      UnitDefinition.linear('m', 'м', 1),
      UnitDefinition.linear('km', 'км', 1000),
      UnitDefinition.linear('inch', 'дюйм', _inch),
      UnitDefinition.linear(
        'inch_fraction',
        'дюйм дробью',
        _inch,
        display: UnitDisplay.inchFraction,
      ),
      UnitDefinition.linear('foot', 'фут', _foot),
      UnitDefinition.linear('yard', 'ярд', _yard),
      UnitDefinition.linear('mile', 'миля', _mile),
    ],
    UnitCategory.area: [
      UnitDefinition.linear('mm2', 'мм²', 1e-6),
      UnitDefinition.linear('cm2', 'см²', 1e-4),
      UnitDefinition.linear('m2', 'м²', 1),
      UnitDefinition.linear('sotka', 'сотка', 100),
      UnitDefinition.linear('ha', 'га', 10000),
      UnitDefinition.linear('km2', 'км²', 1e6),
      UnitDefinition.linear('inch2', 'дюйм²', _inch * _inch),
      UnitDefinition.linear('foot2', 'фут²', _foot * _foot),
      UnitDefinition.linear('acre', 'акр', _yard * _yard * 4840),
    ],
    UnitCategory.volume: [
      UnitDefinition.linear('ml', 'мл', 1e-6),
      UnitDefinition.linear('cm3', 'см³', 1e-6),
      UnitDefinition.linear('l', 'л', 0.001),
      UnitDefinition.linear('m3', 'м³', 1),
      UnitDefinition.linear('inch3', 'дюйм³', _inch * _inch * _inch),
      UnitDefinition.linear('foot3', 'фут³', _foot * _foot * _foot),
      UnitDefinition.linear('gallon_us', 'гал US', _gallonUs),
      UnitDefinition.linear('gallon_uk', 'гал UK', 0.00454609),
      UnitDefinition.linear('barrel_oil', 'баррель', _gallonUs * 42),
    ],
    UnitCategory.mass: [
      UnitDefinition.linear('mg', 'мг', 1e-6),
      UnitDefinition.linear('g', 'г', 0.001),
      UnitDefinition.linear('kg', 'кг', 1),
      UnitDefinition.linear('centner', 'ц', 100),
      UnitDefinition.linear('t', 'т', 1000),
      UnitDefinition.linear('oz', 'унция', _pound / 16),
      UnitDefinition.linear('lb', 'фунт', _pound),
    ],
    UnitCategory.density: [
      UnitDefinition.linear('g_l', 'г/л', 1),
      UnitDefinition.linear('kg_m3', 'кг/м³', 1),
      UnitDefinition.linear('g_cm3', 'г/см³', 1000),
      UnitDefinition.linear('kg_l', 'кг/л', 1000),
      UnitDefinition.linear('t_m3', 'т/м³', 1000),
      UnitDefinition.linear(
        'lb_foot3',
        'фунт/фут³',
        _pound / (_foot * _foot * _foot),
      ),
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
      UnitDefinition.linear('kgf_cm2', 'кгс/см²', _gravity / 1e-4),
      UnitDefinition.linear('psi', 'psi', _poundForce / (_inch * _inch)),
      UnitDefinition.linear('mmhg', 'мм рт. ст.', 133.322387415),
      UnitDefinition.linear('mm_h2o', 'мм вод. ст.', _gravity),
      UnitDefinition.linear('m_h2o', 'м вод. ст.', _gravity * 1000),
    ],
    UnitCategory.speed: [
      UnitDefinition.linear('m_s', 'м/с', 1),
      UnitDefinition.linear('km_h', 'км/ч', 1 / 3.6),
      UnitDefinition.linear('ft_s', 'фут/с', _foot),
      UnitDefinition.linear('mph', 'миль/ч', _mile / 3600),
      UnitDefinition.linear('knot', 'узел', 1852 / 3600),
    ],
    UnitCategory.flow: [
      UnitDefinition.linear('m3_s', 'м³/с', 1),
      UnitDefinition.linear('m3_min', 'м³/мин', 1 / 60),
      UnitDefinition.linear('m3_h', 'м³/ч', 1 / 3600),
      UnitDefinition.linear('l_s', 'л/с', 0.001),
      UnitDefinition.linear('l_min', 'л/мин', 0.001 / 60),
      UnitDefinition.linear('l_h', 'л/ч', 0.001 / 3600),
    ],
    UnitCategory.power: [
      UnitDefinition.linear('w', 'Вт', 1),
      UnitDefinition.linear('kw', 'кВт', 1000),
      UnitDefinition.linear('mw', 'МВт', 1e6),
      UnitDefinition.linear('hp_metric', 'л.с.', 75 * _gravity),
      UnitDefinition.linear(
        'hp_mech',
        'л.с. (мех.)',
        550 * _foot * _poundForce,
      ),
    ],
    UnitCategory.energy: [
      UnitDefinition.linear('j', 'Дж', 1),
      UnitDefinition.linear('kj', 'кДж', 1000),
      UnitDefinition.linear('mj', 'МДж', 1e6),
      UnitDefinition.linear('cal', 'кал', 4.184),
      UnitDefinition.linear('kcal', 'ккал', 4184),
      UnitDefinition.linear('wh', 'Вт·ч', 3600),
      UnitDefinition.linear('kwh', 'кВт·ч', 3.6e6),
    ],
    UnitCategory.torque: [
      UnitDefinition.linear('n_m', 'Н·м', 1),
      UnitDefinition.linear('n_cm', 'Н·см', 0.01),
      UnitDefinition.linear('kgf_m', 'кгс·м', _gravity),
      UnitDefinition.linear('kgf_cm', 'кгс·см', _gravity / 100),
      UnitDefinition.linear('lbf_ft', 'фунт·фут', _poundForce * _foot),
    ],
    UnitCategory.time: [
      UnitDefinition.linear('ms', 'мс', 0.001),
      UnitDefinition.linear('s', 'с', 1),
      UnitDefinition.linear('min', 'мин', 60),
      UnitDefinition.linear('h', 'ч', 3600),
      UnitDefinition.linear('day', 'сут', 86400),
      UnitDefinition.linear('week', 'нед', 604800),
    ],
    UnitCategory.angle: [
      UnitDefinition.linear('arcsecond', 'угл. с', math.pi / 648000),
      UnitDefinition.linear('arcminute', 'угл. мин', math.pi / 10800),
      UnitDefinition.linear('degree', '°', math.pi / 180),
      UnitDefinition.linear('gon', 'гон', math.pi / 200),
      UnitDefinition.linear('radian', 'рад', 1),
      UnitDefinition.linear('turn', 'об', 2 * math.pi),
    ],
    UnitCategory.data: [
      UnitDefinition.linear('bit', 'бит', 0.125),
      UnitDefinition.linear('byte', 'Б', 1),
      UnitDefinition.linear('kb', 'КБ', 1024),
      UnitDefinition.linear('mb', 'МБ', math.pow(1024, 2).toDouble()),
      UnitDefinition.linear('gb', 'ГБ', math.pow(1024, 3).toDouble()),
      UnitDefinition.linear('tb', 'ТБ', math.pow(1024, 4).toDouble()),
      UnitDefinition.linear('pb', 'ПБ', math.pow(1024, 5).toDouble()),
    ],
    UnitCategory.voltage: [
      UnitDefinition.linear('uv', 'мкВ', 1e-6),
      UnitDefinition.linear('mv', 'мВ', 0.001),
      UnitDefinition.linear('v', 'В', 1),
      UnitDefinition.linear('kv', 'кВ', 1000),
    ],
    UnitCategory.current: [
      UnitDefinition.linear('ua', 'мкА', 1e-6),
      UnitDefinition.linear('ma', 'мА', 0.001),
      UnitDefinition.linear('a', 'А', 1),
      UnitDefinition.linear('ka', 'кА', 1000),
    ],
    UnitCategory.resistance: [
      UnitDefinition.linear('mohm', 'мОм', 0.001),
      UnitDefinition.linear('ohm', 'Ом', 1),
      UnitDefinition.linear('kohm', 'кОм', 1000),
      UnitDefinition.linear('megohm', 'МОм', 1e6),
    ],
    UnitCategory.frequency: [
      UnitDefinition.linear('rpm', 'об/мин', 1 / 60),
      UnitDefinition.linear('hz', 'Гц', 1),
      UnitDefinition.linear('khz', 'кГц', 1000),
      UnitDefinition.linear('mhz', 'МГц', 1e6),
      UnitDefinition.linear('ghz', 'ГГц', 1e9),
    ],
  };

  /// Единица величины или `null`, если такой в таблице нет.
  ///
  /// Сохранённый расчёт мог прийти из копии, снятой другой версией: экран
  /// обязан пережить незнакомый ключ, а не упасть на нём.
  static UnitDefinition? unitOrNull(UnitCategory category, String id) {
    for (final unit in units[category]!) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  static double convert({
    required UnitCategory category,
    required String fromUnitId,
    required String toUnitId,
    required double value,
  }) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Value must be finite');
    }
    final from = unitOrNull(category, fromUnitId);
    if (from == null) throw ArgumentError.value(fromUnitId, 'fromUnitId');
    final to = unitOrNull(category, toUnitId);
    if (to == null) throw ArgumentError.value(toUnitId, 'toUnitId');
    final result = to.fromBase(from.toBase(value));
    if (!result.isFinite) {
      throw StateError('Conversion produced a non-finite result');
    }
    return result;
  }
}
