/// Число с единицей измерения и разумной для неё точностью.
///
/// Точность принадлежит величине, а не месту показа. Скорость воздуха с
/// шестью знаками после запятой — не точность, а шум: до микрометра в секунду
/// воздуховод всё равно не считают. Поэтому правило записано один раз здесь,
/// а панели расчётов им пользуются.
library;

import '../localization/engineering_units.dart';
import 'decimal_input.dart';

/// Сколько знаков после запятой показывать у этой единицы.
int engineeringPrecision(EngUnit unit) => switch (unit) {
      EngUnit.volt => 2,
      EngUnit.ampere => 2,
      EngUnit.watt => 1,
      EngUnit.kilowatt => 3,
      EngUnit.millimetreSquared => 1,
      EngUnit.millimetre => 1,
      EngUnit.metre => 2,
      EngUnit.metreSquared => 4,
      EngUnit.metrePerSecond => 2,
      EngUnit.litre => 1,
      EngUnit.litrePerMinute => 1,
      EngUnit.cubicMetrePerHour => 1,
      EngUnit.pascal => 0,
      EngUnit.pascalPerMetre => 1,
      EngUnit.bar => 3,
      EngUnit.metreOfWater => 2,
      EngUnit.second => 0,
      EngUnit.perHour => 1,
      EngUnit.celsius => 0,
      EngUnit.ohm => 3,
      EngUnit.percent => 2,
      EngUnit.person => 0,
    };

/// Значение с обозначением единицы: «2.31 м/с».
String formatEngValue(double value, EngUnit unit, bool ru) =>
    '${formatToolNumber(value, precision: engineeringPrecision(unit))}'
    ' ${unit.symbol(ru)}';
