import 'package:flutter/material.dart';

import 'screen_theme_colors.dart';

/// Полоса матового стекла, на которой стоят кнопки панелей.
///
/// Панели экранных тем не приклеены к краям экрана, как обложка блокнота, а
/// лежат на заднике отдельными полосами с полями по бокам: сквозь них видно
/// фон, и они читаются стеклом, а не краем окна.
class ScreenPanel extends StatelessWidget {
  const ScreenPanel({
    required this.colors,
    required this.edge,
    required this.child,
    super.key,
  });

  final ScreenThemeColors colors;

  /// Верхняя полоса отступает от системной строки, нижняя — от жеста «домой».
  final VerticalDirection edge;

  final Widget child;

  /// Поле между полосой и краем экрана.
  static const double inset = 8;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: edge == VerticalDirection.up,
      bottom: edge == VerticalDirection.down,
      maintainBottomViewPadding: edge == VerticalDirection.down,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          inset,
          edge == VerticalDirection.up ? inset : inset / 2,
          inset,
          edge == VerticalDirection.up ? inset / 2 : inset,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Полоса просвечивает нарочно: это матовое стекло на заднике, а
            // не белая планка поверх него. Цвет панели берётся с ослабленной
            // непрозрачностью, а не заводится отдельным значением: сквозь
            // стекло видно тот же задник, что и вокруг.
            color: colors.panel.withValues(alpha: colors.isDark ? 0.7 : 0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
