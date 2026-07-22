import 'package:ezhednevnik_v2/src/core/theme/app_content_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('content font choice is saved and restored', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = AppContentFontController();
    await controller.setStyle(AppContentFontStyle.lifehack);

    expect(controller.state, AppContentFontStyle.lifehack);
    expect(
      (await SharedPreferences.getInstance())
          .getString(AppContentFontController.storageKey),
      'lifehack',
    );

    final restored = AppContentFontController();
    await Future<void>.delayed(Duration.zero);
    expect(restored.state, AppContentFontStyle.lifehack);
  });

  test('content font defaults to Manrope', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    expect(
      AppContentFontController.readInitialStyle(preferences),
      AppContentFontStyle.manrope,
    );
  });

  test('Patsy Sans uses Manrope as a glyph fallback', () {
    const typography = AppContentTypography(AppContentFontStyle.patsySans);
    final style =
        typography.apply(const TextStyle(fontWeight: FontWeight.w900));

    expect(style.fontFamily, 'PatsySans');
    expect(style.fontFamilyFallback, const ['Manrope']);
    expect(style.fontWeight, FontWeight.w400);
  });
}
