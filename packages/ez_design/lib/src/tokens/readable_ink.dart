import 'package:flutter/material.dart';

/// Чернила, читаемые поверх [background].
///
/// Цвет человек выбирает сам — от почти белого до почти чёрного, — поэтому
/// «белым по цвету» не обойтись: на светлом фоне белое пропадает. Решает
/// светлота самого фона.
Color readableInkOn(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF17140F);
}
