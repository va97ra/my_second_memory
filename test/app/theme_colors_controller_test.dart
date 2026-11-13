import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/app/theme/app_theme_colors_controller.dart';
import 'package:ezhednevnik_v2/src/app/theme/app_theme_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/provider_test_support.dart';

void main() {
  test('colours chosen for a theme are saved and come back after restart',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = testContainer();
    final controller =
        container.read(appThemeColorsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    final dark = container
        .read(appThemeColorsControllerProvider)[AppThemeStyle.notebookDark]!;
    await controller.setColors(
      AppThemeStyle.notebookDark,
      dark
          .withColor(AppColorRole.weekend, AppPalette.indigo)
          .withShiftColor('s1', AppPalette.success.withValues(alpha: 0.5)),
    );

    final preferences = await SharedPreferences.getInstance();
    final restored = AppThemeColorsController.read(preferences);
    expect(
      restored[AppThemeStyle.notebookDark]!.picked(AppColorRole.weekend),
      AppPalette.indigo,
    );
    // Хранится восемь бит на канал: полупрозрачный цвет возвращается тем же
    // числом, а не той же дробью.
    expect(
      restored[AppThemeStyle.notebookDark]!.shifts['s1']!.toARGB32(),
      AppPalette.success.withValues(alpha: 0.5).toARGB32(),
    );
    // Светлая тема не задета: у каждой темы свои цвета.
    expect(restored[AppThemeStyle.notebookLight]!.chosen, isEmpty);
  });

  test('a damaged record reads as no choice at all', () async {
    SharedPreferences.setMockInitialValues(
      {AppThemeColorsController.storageKey: '{not json'},
    );
    final preferences = await SharedPreferences.getInstance();
    final colors = AppThemeColorsController.read(preferences);
    expect(colors[AppThemeStyle.notebookLight]!.chosen, isEmpty);
    expect(colors[AppThemeStyle.notebookDark]!.shifts, isEmpty);
  });

  test('the theme is rebuilt with the chosen accent', () async {
    SharedPreferences.setMockInitialValues({});
    final container = testContainer();
    container.read(appThemeColorsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final light = container
        .read(appThemeColorsControllerProvider)[AppThemeStyle.notebookLight]!;

    await container.read(appThemeColorsControllerProvider.notifier).setColors(
          AppThemeStyle.notebookLight,
          light.withColor(AppColorRole.accent, AppPalette.indigo),
        );

    final theme =
        container.read(appThemeDataProvider(AppThemeStyle.notebookLight));
    expect(theme.colorScheme.primary, AppPalette.indigo);
    final other =
        container.read(appThemeDataProvider(AppThemeStyle.notebookDark));
    expect(other.colorScheme.primary, AppPalette.magenta);
  });
}
