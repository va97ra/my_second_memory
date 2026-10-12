import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../converter/state/converter_controller.dart';
import 'jarvis_calculator.dart';
import 'jarvis_outcome.dart';
import 'jarvis_page.dart';

/// Руки Джарвиса на конвертере величин — как на калькуляторе.
///
/// Переводит сам конвертер: Джарвис выставляет величину, единицы и число и
/// читает ответ с него. Поэтому переведённое голосом стоит на конвертере, а
/// «а в метрах?», «а если 10?», «поменяй местами» продолжают его. Конвертер
/// на экране — число набирается на глазах.
class JarvisConverter {
  JarvisConverter(this._ref);

  final Ref _ref;

  static const _place = OpenPlace(JarvisPlace.converter);

  ConverterController get _hands =>
      _ref.read(converterControllerProvider.notifier);
  ConverterState get _shown => _ref.read(converterControllerProvider);
  bool get _onScreen =>
      _ref.read(jarvisPageProvider)?.place == JarvisPlace.converter;

  /// «Сколько сантиметров в 3 дюймах»: перейти к конвертеру, заполнить и
  /// прочитать ответ — как калькулятор.
  Future<JarvisOutcome> convert(ConvertUnits command) async {
    final before = _shown;
    await comeToPage(_ref, _place);
    await _fill(
        command.category, command.fromUnit, command.toUnit, command.value);
    return _told(before);
  }

  Future<JarvisOutcome> run(ConverterCommand command) async {
    final before = _shown;
    await comeToPage(_ref, _place);
    final unit = command.unit;
    final category = command.category;
    switch (command.move) {
      case ConverterMove.retarget:
        if (unit == null || category != before.category) {
          return const JarvisOutcome(converterMismatch);
        }
        _hands.setUnit(_other(before.entry), unit);
      case ConverterMove.revalue:
        final value = command.value!;
        if (unit != null && category != null && category != before.category) {
          // Другая величина — новый перевод в её единицу по умолчанию.
          final units = UnitConverter.units[category]!;
          final to = units.firstWhere((item) => item.id != unit).id;
          await _fill(category, unit, to, value);
        } else {
          if (unit != null) _hands.setUnit(before.entry, unit);
          await _type(_shown.entry, value);
        }
      case ConverterMove.swap:
        _hands.swap();
    }
    return _told(before);
  }

  /// Выставить перевод: величину и единицы сразу, число — на глазах.
  Future<void> _fill(
      UnitCategory category, String from, String to, double value) async {
    _hands.load(SavedConversionPayload(
      category: category.name,
      fromUnit: from,
      toUnit: to,
      value: value,
    ));
    await _type(ConverterSide.left, value);
  }

  /// Набрать число. Конвертер на экране — по знаку, как пальцем.
  Future<void> _type(ConverterSide side, double value) async {
    final raw = formatToolNumber(value);
    if (!_onScreen) return _hands.setValue(side, raw);
    for (var length = 1; length <= raw.length; length++) {
      _hands.setValue(side, raw.substring(0, length));
      await Future<void>.delayed(JarvisCalculator.press);
    }
  }

  JarvisOutcome _told(ConverterState before) {
    final reading = converterReading(_shown);
    return JarvisOutcome(
      reading == null
          ? JarvisReplies.lookAbout(JarvisPlace.converter)
          : unitReply(reading.asked, reading.result),
      link: _onScreen ? null : _place,
      undo: () async => _hands.restore(before),
    );
  }

  static ConverterSide _other(ConverterSide side) =>
      side == ConverterSide.left ? ConverterSide.right : ConverterSide.left;
}

/// Что сейчас на конвертере — как его видно, слева направо: число левой
/// колонки и правой. Null — в поле не число.
({ConvertUnits asked, double result})? converterReading(ConverterState state) {
  final left = state.reading(ConverterSide.left)?.value;
  final right = state.reading(ConverterSide.right)?.value;
  if (left == null || right == null) return null;
  return (
    asked: ConvertUnits(
      value: left,
      category: state.category,
      fromUnit: state.from,
      toUnit: state.to,
    ),
    result: right,
  );
}
