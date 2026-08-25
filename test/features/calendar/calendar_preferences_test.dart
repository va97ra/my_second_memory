import 'package:ezhednevnik_v2/src/shared/state/bool_setting_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a switched setting persists under its own key', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = BoolSettingController(
      storageKey: 'calendar_hints_enabled_v1',
      initial: true,
    );
    await controller.setEnabled(false);

    expect(controller.state, isFalse);
    expect(
      (await SharedPreferences.getInstance())
          .getBool('calendar_hints_enabled_v1'),
      isFalse,
    );
  });

  test('a stored value wins over the initial one', () async {
    SharedPreferences.setMockInitialValues({
      'calendar_observances_enabled_v1': false,
    });
    final controller = BoolSettingController(
      storageKey: 'calendar_observances_enabled_v1',
      initial: true,
    );

    // Чтение асинхронное: до него переключатель показывает начальное значение.
    expect(controller.state, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, isFalse);
  });
}
