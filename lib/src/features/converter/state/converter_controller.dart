import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final converterControllerProvider =
    StateNotifierProvider<ConverterController, ConverterState>(
  (ref) => ConverterController(),
);

/// Сторона конвертера: слева то, что переводят, справа — во что.
enum ConverterSide { left, right }

/// Число одной стороны: единица и её значение, готовое к чтению.
class ConversionReading {
  const ConversionReading({required this.unit, required this.value});

  final UnitDefinition unit;
  final double value;

  String get number => switch (unit.display) {
        UnitDisplay.inchFraction => formatInchFraction(value),
        UnitDisplay.decimal => formatToolNumber(value),
      };
}

class ConverterState {
  const ConverterState({
    required this.category,
    required this.from,
    required this.to,
    required this.raw,
    required this.entry,
  });

  ConverterState.initial()
      : category = UnitCategory.length,
        from = 'm',
        to = 'cm',
        raw = '1',
        entry = ConverterSide.left;

  final UnitCategory category;

  /// Единица левой стороны.
  final String from;

  /// Единица правой стороны.
  final String to;

  /// Число, набранное человеком, как он его набрал.
  final String raw;

  /// Сторона, в которую набирали. Вторая считается от неё.
  ///
  /// Считать можно в обе стороны, поэтому «исходной» назначается не колонка, а
  /// то поле, которого коснулись последним: набрал слева — ответ справа, начал
  /// править справа — ответ появился слева.
  final ConverterSide entry;

  List<UnitDefinition> get units => UnitConverter.units[category]!;

  /// Дробь — такая же запись числа, как десятичная точка: «3/4» и «1 1/2»
  /// человек набирает ровно так, как читает с фитинга.
  double? get typed => parseFractionalNumber(raw);

  String unitIdOf(ConverterSide side) => side == ConverterSide.left ? from : to;

  /// Число этой стороны. `null`, если в поле не число.
  ConversionReading? reading(ConverterSide side) {
    final input = typed;
    if (input == null) return null;
    final unit = UnitConverter.unitOrNull(category, unitIdOf(side));
    if (unit == null) return null;
    return ConversionReading(
      unit: unit,
      value: UnitConverter.convert(
        category: category,
        fromUnitId: unitIdOf(entry),
        toUnitId: unit.id,
        value: input,
      ),
    );
  }

  ConverterState copyWith({
    UnitCategory? category,
    String? from,
    String? to,
    String? raw,
    ConverterSide? entry,
  }) =>
      ConverterState(
        category: category ?? this.category,
        from: from ?? this.from,
        to: to ?? this.to,
        raw: raw ?? this.raw,
        entry: entry ?? this.entry,
      );
}

class ConverterController extends StateNotifier<ConverterState> {
  ConverterController() : super(ConverterState.initial());

  void setValue(ConverterSide side, String raw) =>
      state = state.copyWith(raw: raw, entry: side);

  void setCategory(UnitCategory category) {
    final units = UnitConverter.units[category]!;
    state = state.copyWith(
      category: category,
      from: units.first.id,
      to: units.length > 1 ? units[1].id : units.first.id,
      entry: ConverterSide.left,
    );
  }

  /// Единица одной из сторон.
  ///
  /// Одна и та же единица с обеих сторон превращает конвертер в зеркало: обе
  /// колонки показывают одно число. Выбор такой единицы поэтому меняет пару
  /// местами, а не схлопывает её.
  void setUnit(ConverterSide side, String unitId) {
    if (unitId == state.unitIdOf(_other(side))) return swap();
    state = side == ConverterSide.left
        ? state.copyWith(from: unitId)
        : state.copyWith(to: unitId);
  }

  /// Колонки меняются местами вместе со своими числами: величина остаётся той
  /// же, меняется только сторона, с которой на неё смотрят.
  void swap() => state = state.copyWith(
        from: state.to,
        to: state.from,
        entry: _other(state.entry),
      );

  /// Сохранённый расчёт мог прийти из копии, снятой другой версией: незнакомую
  /// величину или единицу открывать нечем, и экран остаётся как был.
  void load(SavedConversionPayload payload) {
    UnitCategory? category;
    for (final item in UnitCategory.values) {
      if (item.name == payload.category) category = item;
    }
    if (category == null) return;
    final units = UnitConverter.units[category]!;
    final from = UnitConverter.unitOrNull(category, payload.fromUnit);
    final to = UnitConverter.unitOrNull(category, payload.toUnit);
    state = ConverterState(
      category: category,
      from: from?.id ?? units.first.id,
      to: to?.id ?? units.last.id,
      raw: formatToolNumber(payload.value),
      entry: ConverterSide.left,
    );
  }

  ConverterSide _other(ConverterSide side) =>
      side == ConverterSide.left ? ConverterSide.right : ConverterSide.left;
}
