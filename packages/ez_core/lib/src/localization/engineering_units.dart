/// Единицы инженерных расчётов: обозначение и его расшифровка словом.
///
/// Одно место на всё приложение. Пока подписи стояли строками прямо в полях,
/// «V» жило в одном файле, «А» в другом, и по-русски они не назывались нигде.
library;

enum EngUnit {
  volt,
  ampere,
  watt,
  kilowatt,
  millimetreSquared,
  millimetre,
  metre,
  metreSquared,
  metrePerSecond,
  litre,
  litrePerMinute,
  cubicMetrePerHour,
  pascal,
  pascalPerMetre,
  bar,
  metreOfWater,
  second,
}

extension EngUnitText on EngUnit {
  /// Обозначение: по-русски кириллицей, как принято в отечественных нормах.
  String symbol(bool isRu) => switch (this) {
        EngUnit.volt => isRu ? 'В' : 'V',
        EngUnit.ampere => isRu ? 'А' : 'A',
        EngUnit.watt => isRu ? 'Вт' : 'W',
        EngUnit.kilowatt => isRu ? 'кВт' : 'kW',
        EngUnit.millimetreSquared => isRu ? 'мм²' : 'mm²',
        EngUnit.millimetre => isRu ? 'мм' : 'mm',
        EngUnit.metre => isRu ? 'м' : 'm',
        EngUnit.metreSquared => isRu ? 'м²' : 'm²',
        EngUnit.metrePerSecond => isRu ? 'м/с' : 'm/s',
        EngUnit.litre => isRu ? 'л' : 'L',
        EngUnit.litrePerMinute => isRu ? 'л/мин' : 'L/min',
        EngUnit.cubicMetrePerHour => isRu ? 'м³/ч' : 'm³/h',
        EngUnit.pascal => isRu ? 'Па' : 'Pa',
        EngUnit.pascalPerMetre => isRu ? 'Па/м' : 'Pa/m',
        EngUnit.bar => isRu ? 'бар' : 'bar',
        EngUnit.metreOfWater => isRu ? 'м вод. ст.' : 'm H₂O',
        EngUnit.second => isRu ? 'с' : 's',
      };

  /// Расшифровка словом — то, что читают вслух.
  String name(bool isRu) => switch (this) {
        EngUnit.volt => isRu ? 'вольт' : 'volt',
        EngUnit.ampere => isRu ? 'ампер' : 'ampere',
        EngUnit.watt => isRu ? 'ватт' : 'watt',
        EngUnit.kilowatt => isRu ? 'киловатт' : 'kilowatt',
        EngUnit.millimetreSquared =>
          isRu ? 'квадратный миллиметр' : 'square millimetre',
        EngUnit.millimetre => isRu ? 'миллиметр' : 'millimetre',
        EngUnit.metre => isRu ? 'метр' : 'metre',
        EngUnit.metreSquared => isRu ? 'квадратный метр' : 'square metre',
        EngUnit.metrePerSecond =>
          isRu ? 'метр в секунду' : 'metre per second',
        EngUnit.litre => isRu ? 'литр' : 'litre',
        EngUnit.litrePerMinute =>
          isRu ? 'литр в минуту' : 'litre per minute',
        EngUnit.cubicMetrePerHour =>
          isRu ? 'кубометр в час' : 'cubic metre per hour',
        EngUnit.pascal => isRu ? 'паскаль' : 'pascal',
        EngUnit.pascalPerMetre =>
          isRu ? 'паскаль на метр' : 'pascal per metre',
        EngUnit.bar => isRu ? 'бар' : 'bar',
        EngUnit.metreOfWater =>
          isRu ? 'метр водяного столба' : 'metre of water column',
        EngUnit.second => isRu ? 'секунда' : 'second',
      };
}
