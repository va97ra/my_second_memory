import 'package:flutter/material.dart';

import 'screen_theme_colors.dart';
import 'screen_visuals.dart';

/// Пластина стекла: чем её рисуют панели, карточки и плитки экранных тем.
///
/// Матовая у пластины только изнанка — она и даёт ровное поле. Толщина
/// остаётся прозрачной: сквозь кромку виден задник, она лишь подкрашена
/// светом с одной стороны и притенена с другой. Пока кромка была плотнее
/// изнанки, всё вместе читалось мутной плёнкой, а не стеклом.
///
/// Кромка узкая. Сверху пластину видно с торца лишь краем: полоса в восьмую
/// высоты читается уже скосом, а не толщиной.
abstract final class GlassSurface {
  /// Доля высоты, которую занимает кромка сверху и снизу.
  ///
  /// Узкая нарочно: сверху пластину видно с торца лишь краем. Полоса в
  /// восьмую высоты читается скосом, а не толщиной.
  static const double edge = 0.045;

  /// Плотность изнанки. Сквозь неё должно быть видно, что лежит на заднике, —
  /// иначе пластина читается плёнкой, а не стеклом.
  static const double lightOpacity = 0.3;
  static const double darkOpacity = 0.42;

  static double opacityFor(ScreenThemeColors colors) =>
      colors.isDark ? darkOpacity : lightOpacity;

  static BoxDecoration? maybeOf(
    BuildContext context, {
    required BorderRadius radius,
    double? opacity,
  }) {
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    if (screen == null) return null;
    return decoration(screen, radius: radius, opacity: opacity);
  }

  static BoxDecoration decoration(
    ScreenThemeColors colors, {
    required BorderRadius radius,
    double? opacity,
  }) {
    return BoxDecoration(
      gradient: gradient(
        colors,
        colors.panel.withValues(alpha: opacity ?? opacityFor(colors)),
      ),
      borderRadius: radius,
      boxShadow: shadow(colors),
    );
  }

  /// Тень под пластиной: она лежит на заднике, а не врезана в него.
  static List<BoxShadow> shadow(ScreenThemeColors colors) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: colors.isDark ? 0.45 : 0.14),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  /// Переход поперёк пластины: кромка сверху освещена, снизу в тени.
  ///
  /// Обводки у стекла нет. Ровная линия по всему контуру — примета
  /// нарисованного прямоугольника: у настоящей пластины светится только та
  /// кромка, на которую падает свет, а противоположная уходит в тень.
  static LinearGradient gradient(ScreenThemeColors colors, Color back) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.glint.withValues(alpha: colors.isDark ? 0.7 : 0.85),
        back,
        back,
        Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.22),
      ],
      stops: const [0, edge, 1 - edge, 1],
    );
  }
}
