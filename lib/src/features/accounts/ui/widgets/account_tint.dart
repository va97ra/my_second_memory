import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Цвета карточки аккаунта по её оттенку. Лист бледный, чтобы текст читался,
/// полоса сверху и образец на палитре того же оттенка, но густые.
Color accountTintAccent(int? hue) => hue == null
    ? AppPalette.account
    : HSLColor.fromAHSL(1, hue.toDouble(), 0.72, 0.5).toColor();

Color? accountTintSurface(int? hue) => hue == null
    ? null
    : HSLColor.fromAHSL(0.6, hue.toDouble(), 0.85, 0.7).toColor();
