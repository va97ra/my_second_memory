import 'package:ez_design/ez_design.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezhednevnik_v2/src/app/theme/app_theme_controller.dart';

void main() {
  test('theme choice is saved and restored', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = AppThemeController();
    await controller.setStyle(AppThemeStyle.notebookDark);

    expect(controller.state, AppThemeStyle.notebookDark);
    expect(
      (await SharedPreferences.getInstance()).getString('app_theme_style_v2'),
      'notebookDark',
    );

    final restored = AppThemeController();
    await Future<void>.delayed(Duration.zero);
    expect(restored.state, AppThemeStyle.notebookDark);
  });

  test('legacy light theme choice migrates to the light notebook', () async {
    SharedPreferences.setMockInitialValues({'app_light_theme_v1': true});

    final controller = AppThemeController();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state, AppThemeStyle.notebookLight);
  });

  test('the retired flat themes migrate by brightness', () {
    expect(AppThemeStyle.fromStorage('light'), AppThemeStyle.notebookLight);
    expect(AppThemeStyle.fromStorage('notebook'), AppThemeStyle.notebookLight);
    expect(AppThemeStyle.fromStorage('dark'), AppThemeStyle.notebookDark);
    expect(AppThemeStyle.fromStorage('nonsense'), isNull);
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
