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

  /// Скругление полосы.
  ///
  /// Единственное место, где радиус не восьмёрка. Плавающая полоса — не
  /// карточка и не кнопка: она читается стеклянной пластиной, лежащей на
  /// заднике, а пластина с углом в восемь пикселей выглядит вырезанной из
  /// листа. На виде, присланном владельцем, у неё крупное скругление, и оно
  /// же отличает её от всего, что лежит внутри.
  static const double radius = 22;

  @override
  Widget build(BuildContext context) {
    final top = edge == VerticalDirection.up;
    const rounded = Radius.circular(radius);
    final shape = BorderRadius.vertical(
      top: rounded,
      bottom: top ? rounded : Radius.zero,
    );
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        // Полоса просвечивает нарочно: это матовое стекло на заднике, а не
        // белая планка поверх него. Цвет панели берётся с ослабленной
        // непрозрачностью, а не заводится отдельным значением: сквозь стекло
        // видно тот же задник, что и вокруг.
        color: colors.panel.withValues(alpha: colors.isDark ? 0.7 : 0.55),
        borderRadius: shape,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.1),
            blurRadius: 12,
            offset: Offset(0, top ? 3 : -3),
          ),
        ],
      ),
      // Нижняя полоса доходит до самого низа экрана, а системную зону жеста
      // держит внутри себя: висящая над краем полоса оставляет под собой
      // полоску задника, и панель перестаёт быть опорой экрана.
      child: top
          ? child
          : SafeArea(top: false, maintainBottomViewPadding: true, child: child),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        inset,
        top ? inset : inset / 2,
        inset,
        top ? inset / 2 : 0,
      ),
      child: top ? SafeArea(bottom: false, child: panel) : panel,
    );
  }
}
