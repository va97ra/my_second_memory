/// Выбор сечения жилы по нагрузке.
///
/// Таблицы допустимого длительного тока взяты из ПУЭ, 7-е издание:
/// таблица 1.3.4 — медные жилы, таблица 1.3.5 — алюминиевые, провода и шнуры
/// с резиновой и поливинилхлоридной изоляцией.
///
/// Значения приведены для температуры жил +65 °C, окружающего воздуха +25 °C.
/// Ни поправок на температуру, ни на число проложенных рядом кабелей, ни на
/// способ прокладки сверх трёх перечисленных здесь нет: это подсказка, а не
/// проект. Ответ показывается вместе с условиями, при которых он получен.
library;

import 'numeric_guards.dart';

enum ConductorMaterial { copper, aluminium }

/// Способ прокладки. Чем теснее жилам, тем хуже они остывают, и тем меньше
/// тока таблица разрешает при том же сечении.
enum WireRouting {
  /// Открыто проложенный провод.
  openAir,

  /// Две одножильные в одной трубе — однофазная линия.
  conduitTwo,

  /// Три одножильные в одной трубе — трёхфазная линия.
  conduitThree,
}

class WireSizingResult {
  const WireSizingResult({
    required this.sectionMm2,
    required this.allowableCurrentA,
    required this.currentA,
    required this.breakerA,
  });

  /// Сечение жилы, мм².
  final double sectionMm2;

  /// Сколько тока таблица разрешает этому сечению при выбранных условиях.
  final double allowableCurrentA;

  /// Расчётный ток нагрузки.
  final double currentA;

  /// Номинал автомата из стандартного ряда: не меньше тока нагрузки и не
  /// больше того, что выдержит жила. `null` — подходящего номинала нет, и
  /// линию нужно делить или брать сечение больше.
  final int? breakerA;

  /// Запас: во сколько раз допустимый ток больше расчётного.
  double get margin => currentA == 0 ? double.infinity : allowableCurrentA / currentA;
}

/// Стандартный ряд номиналов автоматических выключателей.
const breakerRatingsA = [6, 10, 16, 20, 25, 32, 40, 50, 63, 80, 100];

/// Ток однофазной нагрузки.
double singlePhaseCurrent({
  required double powerW,
  required double voltageV,
  double powerFactor = 1,
}) {
  positiveValue(voltageV, 'voltageV');
  fractionValue(powerFactor, 'powerFactor');
  nonNegativeValue(powerW, 'powerW');
  return powerW / (voltageV * powerFactor);
}

/// Ток трёхфазной нагрузки.
double threePhaseCurrent({
  required double powerW,
  required double lineVoltageV,
  double powerFactor = 1,
}) {
  positiveValue(lineVoltageV, 'lineVoltageV');
  fractionValue(powerFactor, 'powerFactor');
  nonNegativeValue(powerW, 'powerW');
  return powerW / (1.7320508075688772 * lineVoltageV * powerFactor);
}

/// Наименьшее сечение, которому таблица разрешает этот ток.
///
/// `null` означает, что ток вышел за таблицу — это не ноль и не «подойдёт
/// самое толстое»: за пределами таблицы ответа нет, и его нельзя выдумывать.
WireSizingResult? selectWireSection({
  required double currentA,
  ConductorMaterial material = ConductorMaterial.copper,
  WireRouting routing = WireRouting.conduitThree,
}) {
  nonNegativeValue(currentA, 'currentA');
  final rows = _tables[material]!;
  for (final row in rows) {
    final allowable = row.allowable[routing.index];
    if (allowable < currentA) continue;
    return WireSizingResult(
      sectionMm2: row.sectionMm2,
      allowableCurrentA: allowable.toDouble(),
      currentA: currentA,
      breakerA: _breakerFor(currentA: currentA, allowableA: allowable),
    );
  }
  return null;
}

/// Номинал защиты: не меньше тока нагрузки и не больше того, что выдержит
/// жила. Автомат защищает провод, а не прибор, — поэтому верхняя граница
/// именно по проводу.
int? _breakerFor({required double currentA, required int allowableA}) {
  for (final rating in breakerRatingsA) {
    if (rating < currentA) continue;
    return rating <= allowableA ? rating : null;
  }
  return null;
}

class _WireRow {
  const _WireRow(this.sectionMm2, this.allowable);

  final double sectionMm2;

  /// Допустимый ток в порядке [WireRouting]: открыто, две в трубе, три в трубе.
  final List<int> allowable;
}

const _tables = <ConductorMaterial, List<_WireRow>>{
  // ПУЭ, таблица 1.3.4.
  ConductorMaterial.copper: [
    _WireRow(1.5, [23, 19, 17]),
    _WireRow(2.5, [30, 27, 25]),
    _WireRow(4, [41, 38, 35]),
    _WireRow(6, [50, 46, 42]),
    _WireRow(10, [80, 70, 60]),
    _WireRow(16, [100, 85, 80]),
    _WireRow(25, [140, 115, 100]),
    _WireRow(35, [170, 135, 125]),
    _WireRow(50, [215, 185, 170]),
  ],
  // ПУЭ, таблица 1.3.5. Алюминий тоньше 2,5 мм² в жилых линиях не применяют.
  ConductorMaterial.aluminium: [
    _WireRow(2.5, [24, 20, 19]),
    _WireRow(4, [32, 28, 28]),
    _WireRow(6, [39, 36, 32]),
    _WireRow(10, [60, 50, 47]),
    _WireRow(16, [75, 60, 60]),
    _WireRow(25, [105, 85, 80]),
    _WireRow(35, [130, 100, 95]),
    _WireRow(50, [165, 140, 130]),
  ],
};
