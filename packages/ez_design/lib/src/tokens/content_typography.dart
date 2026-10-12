import 'package:flutter/material.dart';

/// Шрифт, которым набрано содержимое записей.
///
/// Служебный интерфейс всегда набран Manrope; выбор здесь касается только
/// текста, который написал пользователь.
enum AppContentFontStyle {
  manrope,
  ptSans,
  montserrat,
  nunito,
  rubik,
  comfortaa,
  lora,
  ptSerif,
  playfairDisplay,
  caveat,
  marckScript,
  ptMono,
  lifehack,
  patsySans;

  /// Семейство из pubspec.yaml — одно и для настроек, и для оформления
  /// куска текста в записи.
  String get family => switch (this) {
        AppContentFontStyle.manrope => 'Manrope',
        AppContentFontStyle.ptSans => 'PTSans',
        AppContentFontStyle.montserrat => 'Montserrat',
        AppContentFontStyle.nunito => 'Nunito',
        AppContentFontStyle.rubik => 'Rubik',
        AppContentFontStyle.comfortaa => 'Comfortaa',
        AppContentFontStyle.lora => 'Lora',
        AppContentFontStyle.ptSerif => 'PTSerif',
        AppContentFontStyle.playfairDisplay => 'PlayfairDisplay',
        AppContentFontStyle.caveat => 'Caveat',
        AppContentFontStyle.marckScript => 'MarckScript',
        AppContentFontStyle.ptMono => 'PTMono',
        AppContentFontStyle.lifehack => 'Lifehack',
        AppContentFontStyle.patsySans => 'PatsySans',
      };

  String get label => switch (this) {
        AppContentFontStyle.manrope => 'Manrope',
        AppContentFontStyle.ptSans => 'PT Sans',
        AppContentFontStyle.montserrat => 'Montserrat',
        AppContentFontStyle.nunito => 'Nunito',
        AppContentFontStyle.rubik => 'Rubik',
        AppContentFontStyle.comfortaa => 'Comfortaa',
        AppContentFontStyle.lora => 'Lora',
        AppContentFontStyle.ptSerif => 'PT Serif',
        AppContentFontStyle.playfairDisplay => 'Playfair Display',
        AppContentFontStyle.caveat => 'Caveat',
        AppContentFontStyle.marckScript => 'Marck Script',
        AppContentFontStyle.ptMono => 'PT Mono',
        AppContentFontStyle.lifehack => 'Lifehack',
        AppContentFontStyle.patsySans => 'Patsy Sans',
      };

  /// Есть ли у шрифта начертания разной жирности. У рукописных и
  /// декоративных одно — для них жирность не задаётся, иначе Flutter
  /// дорисовывает её сам и буквы расплываются.
  bool get hasWeights => switch (this) {
        AppContentFontStyle.marckScript ||
        AppContentFontStyle.ptMono ||
        AppContentFontStyle.lifehack ||
        AppContentFontStyle.patsySans =>
          false,
        _ => true,
      };

  static AppContentFontStyle fromStorage(String? value) {
    return AppContentFontStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => AppContentFontStyle.manrope,
    );
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
      fontWeight: style.hasWeights
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
