import 'package:ezhednevnik_v2/src/core/theme/app_theme_controller.dart';
import 'package:ezhednevnik_v2/src/core/theme/app_theme_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme choice is saved and restored', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = AppThemeController();
    await controller.setStyle(AppThemeStyle.notebook);

    expect(controller.state, AppThemeStyle.notebook);
    expect(
      (await SharedPreferences.getInstance()).getString('app_theme_style_v2'),
      'notebook',
    );

    final restored = AppThemeController();
    await Future<void>.delayed(Duration.zero);
    expect(restored.state, AppThemeStyle.notebook);
  });

  test('legacy light theme choice migrates to light style', () async {
    SharedPreferences.setMockInitialValues({'app_light_theme_v1': true});

    final controller = AppThemeController();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state, AppThemeStyle.light);
  });

  test('fresh install uses the controller default style', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    expect(
      AppThemeController.readInitialStyle(preferences),
      AppThemeController.defaultStyle,
    );
  });
}
