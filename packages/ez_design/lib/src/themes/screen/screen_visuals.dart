import 'package:flutter/material.dart';

import 'screen_theme_colors.dart';

/// Значения темы-экрана, доступные виджетам.
///
/// Работает так же, как `NotebookVisuals`: тема кладёт расширение, а виджет
/// спрашивает его и рисует себя соответственно. Тема, которая расширения не
/// положила, — блокнотная, и экранных приёмов в ней нет.
@immutable
class ScreenVisuals extends ThemeExtension<ScreenVisuals> {
  const ScreenVisuals(this.colors);

  final ScreenThemeColors colors;

  static ScreenVisuals? maybeOf(BuildContext context) {
    return Theme.of(context).extension<ScreenVisuals>();
  }

  @override
  ScreenVisuals copyWith({ScreenThemeColors? colors}) {
    return ScreenVisuals(colors ?? this.colors);
  }

  /// Промежуточного набора значений между двумя темами не существует: это не
  /// оттенок, а другое оформление целиком. Поэтому переход не смешивает их, а
  /// переключает на середине.
  @override
  ScreenVisuals lerp(covariant ScreenVisuals? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
