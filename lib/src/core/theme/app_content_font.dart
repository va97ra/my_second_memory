import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppContentFontStyle {
  manrope,
  lifehack,
  patsySans;

  String get family => switch (this) {
        AppContentFontStyle.manrope => 'Manrope',
        AppContentFontStyle.lifehack => 'Lifehack',
        AppContentFontStyle.patsySans => 'PatsySans',
      };

  String get label => switch (this) {
        AppContentFontStyle.manrope => 'Manrope',
        AppContentFontStyle.lifehack => 'Lifehack',
        AppContentFontStyle.patsySans => 'Patsy Sans',
      };

  static AppContentFontStyle fromStorage(String? value) {
    return AppContentFontStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => AppContentFontStyle.manrope,
    );
  }
}

final appContentFontControllerProvider =
    StateNotifierProvider<AppContentFontController, AppContentFontStyle>(
  (ref) => AppContentFontController(),
);

class AppContentFontController extends StateNotifier<AppContentFontStyle> {
  AppContentFontController({
    AppContentFontStyle initialStyle = AppContentFontStyle.manrope,
    SharedPreferences? preferences,
    bool loadOnStart = true,
  })  : _preferences = preferences,
        super(initialStyle) {
    if (loadOnStart) _load();
  }

  static const storageKey = 'app_content_font_v1';
  SharedPreferences? _preferences;

  static AppContentFontStyle readInitialStyle(SharedPreferences preferences) {
    return AppContentFontStyle.fromStorage(preferences.getString(storageKey));
  }

  Future<void> _load() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    state = readInitialStyle(preferences);
  }

  Future<void> setStyle(AppContentFontStyle style) async {
    state = style;
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(storageKey, style.name);
  }
}

@immutable
class AppContentTypography extends ThemeExtension<AppContentTypography> {
  const AppContentTypography(this.style);

  final AppContentFontStyle style;

  static AppContentTypography of(BuildContext context) {
    return Theme.of(context).extension<AppContentTypography>() ??
        const AppContentTypography(AppContentFontStyle.manrope);
  }

  TextStyle apply(TextStyle? base, {FontWeight? manropeWeight}) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: style.family,
      fontFamilyFallback: const ['Manrope'],
      fontWeight: style == AppContentFontStyle.manrope
          ? manropeWeight ?? base?.fontWeight
          : FontWeight.w400,
    );
  }

  double measuredLineHeight(TextStyle style, {String sample = 'АЁgj'}) {
    final painter = TextPainter(
      text: TextSpan(text: sample, style: apply(style)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final metrics = painter.computeLineMetrics();
    return metrics.isEmpty
        ? (style.fontSize ?? 14) * (style.height ?? 1.2)
        : metrics.first.height;
  }

  @override
  AppContentTypography copyWith({AppContentFontStyle? style}) {
    return AppContentTypography(style ?? this.style);
  }

  @override
  AppContentTypography lerp(
    covariant AppContentTypography? other,
    double t,
  ) {
    return t < 0.5 || other == null ? this : other;
  }
}
