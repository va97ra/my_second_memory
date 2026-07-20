import 'package:ezhednevnik_v2/src/features/calendar/state/calendar_preferences_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('calendar hint setting persists', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppHintsController();
    await controller.setEnabled(false);

    expect(controller.state, isFalse);
    expect(
      (await SharedPreferences.getInstance())
          .getBool(AppHintsController.storageKey),
      isFalse,
    );
  });
}
