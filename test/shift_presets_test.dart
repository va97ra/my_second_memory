import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a known pattern is recognised as a preset', () {
    expect(shiftPresetFor(5, 2)?.key, '5/2');
    expect(shiftPresetFor(2, 2)?.key, '2/2');
    expect(shiftPresetFor(1, 3)?.key, '1/3');
  });

  test('an unusual pattern stays a manual schedule', () {
    expect(shiftPresetFor(3, 1), isNull);
    expect(shiftPresetFor(0, 0), isNull);
  });

  test('only the round-the-clock pattern crosses midnight', () {
    expect(supportsNextDayAlarmFor(1, 3), isTrue);
    expect(supportsNextDayAlarmFor(5, 2), isFalse);
    expect(supportsNextDayAlarmFor(2, 2), isFalse);
  });

  test('every preset names itself in both languages', () {
    for (final preset in shiftPresets) {
      expect(preset.label('ru'), isNotEmpty);
      expect(preset.label('en'), isNotEmpty);
      expect(preset.workDays, greaterThan(0));
      expect(preset.restDays, greaterThan(0));
    }
  });
}
