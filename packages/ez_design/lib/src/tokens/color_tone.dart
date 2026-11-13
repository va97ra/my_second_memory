import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Цвет, разобранный на две ручки: оттенок и светлоту.
///
/// Пикер показывает полосы, а хранится один `Color` — перевод между ними
/// живёт здесь, чтобы виджет только рисовал и не считал.
@immutable
class ColorTone {
  const ColorTone({required this.hue, required this.tone});

  /// Насыщенность и яркость самой яркой точки шкалы: середина полосы
  /// светлоты.
  static const _baseSaturation = 0.82;
  static const _baseValue = 0.92;

  /// Оттенок цвета из существующего значения.
  ///
  /// У серого оттенка нет, поэтому он читается как красный: иначе ручка
  /// прыгала бы в случайное место шкалы.
  factory ColorTone.fromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    final hue = hsv.saturation < 0.02 ? 0.0 : hsv.hue;
    if (hsv.value >= _baseValue) {
      final light = _unit((hsv.saturation - 0.08) / (_baseSaturation - 0.08));
      return ColorTone(hue: hue, tone: light * 0.5);
    }
    final dark = _unit((_baseValue - hsv.value) / (_baseValue - 0.24));
    return ColorTone(hue: hue, tone: 0.5 + dark * 0.5);
  }

  /// Оттенок, 0..360.
  final double hue;

  /// Светлота, 0..1: 0 — почти белый, 0.5 — чистый цвет, 1 — почти чёрный.
  final double tone;

  Color get color => colorAtTone(tone);

  /// Чистый цвет этого оттенка — середина полосы светлоты.
  Color get vividColor =>
      HSVColor.fromAHSV(1, hue, _baseSaturation, _baseValue).toColor();

  Color get lightestColor => HSVColor.fromAHSV(1, hue, 0.08, 1).toColor();

  Color get darkestColor => HSVColor.fromAHSV(1, hue, 0.92, 0.24).toColor();

  Color get thumbColor => HSVColor.fromAHSV(1, hue, 0.86, 0.96).toColor();

  ColorTone withHuePosition(double position) =>
      ColorTone(hue: _unit(position) * 360, tone: tone);

  ColorTone withTonePosition(double position) =>
      ColorTone(hue: hue, tone: _unit(position));

  Color colorAtTone(double value) {
    if (value <= 0.5) {
      final progress = value * 2;
      return HSVColor.fromAHSV(
        1,
        hue,
        _lerp(0.08, _baseSaturation, progress),
        _lerp(1, _baseValue, progress),
      ).toColor();
    }
    final progress = (value - 0.5) * 2;
    return HSVColor.fromAHSV(
      1,
      hue,
      _lerp(_baseSaturation, 0.92, progress),
      _lerp(_baseValue, 0.24, progress),
    ).toColor();
  }

  static double _unit(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  static double _lerp(double start, double end, double progress) =>
      start + (end - start) * progress;
}
