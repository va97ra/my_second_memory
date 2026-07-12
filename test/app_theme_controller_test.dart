import 'package:ezhednevnik_v2/src/core/theme/app_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme choice is saved and restored', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = AppThemeController();
    await controller.setLight(true);

    expect(controller.state, ThemeMode.light);
    expect(
      (await SharedPreferences.getInstance()).getBool('app_light_theme_v1'),
      isTrue,
    );

    final restored = AppThemeController();
    await Future<void>.delayed(Duration.zero);
    expect(restored.state, ThemeMode.light);
  });
}
