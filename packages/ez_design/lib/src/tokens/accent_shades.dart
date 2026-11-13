import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Оттенки акцента, из которых собрана кнопка: нажатая, блик, тень, подложка
/// и чернила на ней.
///
/// Считаются от самого акцента, чтобы любой выбранный человеком цвет давал
/// такую же объёмную кнопку. Сдвиги подобраны по исходному малиновому: из него
/// выходят прежние оттенки, каждый канал ближе 16 единиц к прежнему
/// (`test/design/app_theme_colors_test.dart`).
@immutable
class AccentShades {
  factory AccentShades.of(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    Color shift(double lightness, [double saturation = 1]) => hsl
        .withLightness((hsl.lightness + lightness).clamp(0.08, 0.95))
        .withSaturation((hsl.saturation * saturation).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: accent.a);
    return AccentShades._(
      deep: shift(-0.17, 0.82),
      light: shift(0.09),
      shadow: shift(-0.33, 0.83),
      tint: shift(0.32),
      ink: shift(-0.43, 0.9),
    );
  }

  const AccentShades._({
    required this.deep,
    required this.light,
    required this.shadow,
    required this.tint,
    required this.ink,
  });

  /// Нажатая кнопка и низ её заливки.
  final Color deep;

  /// Блик сверху и обводка кнопки.
  final Color light;
  final Color shadow;

  /// Бледная подложка под акцентом.
  final Color tint;

  /// Чернила на бледной подложке.
  final Color ink;
}
