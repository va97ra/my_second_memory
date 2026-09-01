import 'package:ez_core/ez_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Подсказка стоит под полем, а поле занимает половину ширины экрана.
/// Длинная фраза там не помещается и обрывается многоточием — это уже
/// случилось однажды, поэтому длина проверяется тестом, а не глазами.
const _limit = 34;

void main() {
  for (final locale in AppStrings.supportedLocales) {
    test('подсказки полей умещаются в колонку: ${locale.languageCode}', () {
      final strings = AppStrings(locale);
      final hints = <String, String>{
        'hintVoltage': strings.hintVoltage,
        'hintLoadCurrent': strings.hintLoadCurrent,
        'hintPowerFactor': strings.hintPowerFactor,
        'hintEfficiency': strings.hintEfficiency,
        'hintOneWayLength': strings.hintOneWayLength,
        'hintSection': strings.hintSection,
        'hintLoadPower': strings.hintLoadPower,
        'hintResistance': strings.hintResistance,
        'hintMaterial': strings.hintMaterial,
        'hintRouting': strings.hintRouting,
        'hintFlow': strings.hintFlow,
        'hintInternalDiameter': strings.hintInternalDiameter,
        'hintTargetVelocity': strings.hintTargetVelocity,
        'hintPipeLength': strings.hintPipeLength,
        'hintHead': strings.hintHead,
        'hintRoughness': strings.hintRoughness,
        'hintAirflow': strings.hintAirflow,
        'hintDuctSide': strings.hintDuctSide,
        'hintRoomSide': strings.hintRoomSide,
        'hintAirChanges': strings.hintAirChanges,
      };
      for (final entry in hints.entries) {
        expect(
          entry.value.length,
          lessThanOrEqualTo(_limit),
          reason: '${entry.key}: «${entry.value}»',
        );
        expect(entry.value.trim(), entry.value, reason: entry.key);
      }
    });
  }
}
