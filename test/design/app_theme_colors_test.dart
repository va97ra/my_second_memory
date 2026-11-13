import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Цвета, которые человек выбирает сам: что по умолчанию, как ложится
/// прозрачность и как из акцента получается кнопка.
void main() {
  const light = AppThemeColors(Brightness.light);
  const dark = AppThemeColors(Brightness.dark);

  test('defaults keep the owner choices of 4 November 2026', () {
    expect(light[AppColorRole.weekend], AppPalette.magenta);
    expect(light[AppColorRole.accent], AppPalette.magenta);
    // На серебре голубой теряется, поэтому сегодня в светлой теме синее.
    expect(light[AppColorRole.today], AppPalette.indigo);
    expect(dark[AppColorRole.today], AppPalette.cyan);
  });

  test('a translucent colour lies on its paper instead of showing leather', () {
    final faint = light.withColor(
      AppColorRole.weekend,
      AppPalette.indigo.withValues(alpha: 0.5),
    );
    final weekend = faint[AppColorRole.weekend];
    expect(weekend.a, 1);
    expect(
      weekend,
      Color.alphaBlend(
        AppPalette.indigo.withValues(alpha: 0.5),
        AppPalette.paperDay,
      ),
    );
  });

  test('choosing the original colour stores nothing', () {
    final same = light.withColor(AppColorRole.weekend, AppPalette.magenta);
    expect(same.chosen, isEmpty);
    expect(same, light);
  });

  test('a shift schedule keeps its own colour until the theme replaces it', () {
    const own = Color(0xFF2F7DD1);
    expect(light.shift('s1', own), own);
    final green = light.withShiftColor('s1', AppPalette.success);
    expect(green.shift('s1', own), AppPalette.success);
    expect(green.shift('s2', own), own);
    expect(green.withShiftColor('s1', null).shifts, isEmpty);
  });

  test('themes keep their colours apart', () {
    final blue = dark.withColor(AppColorRole.weekend, AppPalette.indigo);
    expect(blue, isNot(dark));
    expect(blue[AppColorRole.weekend], AppPalette.indigo);
    expect(light[AppColorRole.weekend], AppPalette.magenta);
  });

  test('the default accent rebuilds the former magenta button', () {
    final shades = AccentShades.of(AppPalette.magenta);
    void near(Color actual, int expected) {
      final target = Color(expected);
      for (final (a, b) in [
        (actual.r, target.r),
        (actual.g, target.g),
        (actual.b, target.b),
      ]) {
        expect((a - b).abs() * 255, lessThan(16), reason: '$actual vs $target');
      }
    }

    near(shades.deep, 0xFFC4146B);
    near(shades.light, 0xFFFF5CAC);
    near(shades.shadow, 0xFF7A0B43);
    near(shades.tint, 0xFFFFD1E6);
    near(shades.ink, 0xFF4D0429);
  });

  test('the theme reads the accent and the ink on it from the colours', () {
    final yellow = light.withColor(AppColorRole.accent, AppPalette.amber);
    final theme = buildNotebookTheme(colors: yellow);
    expect(theme.colorScheme.primary, AppPalette.amber);
    // На жёлтой кнопке белые буквы не читаются.
    expect(theme.colorScheme.onPrimary, readableInkOn(AppPalette.amber));
    expect(theme.extension<AppThemeColors>(), yellow);
  });

  test('paper inside the dark theme keeps the dark theme colours', () {
    final blue = dark.withColor(AppColorRole.weekend, AppPalette.indigo);
    final page = buildNotebookTheme(brightness: Brightness.dark, colors: blue);
    final paper = loosePaperTheme(page);
    expect(paper.brightness, Brightness.light);
    expect(paper.extension<AppThemeColors>(), blue);
  });
}
