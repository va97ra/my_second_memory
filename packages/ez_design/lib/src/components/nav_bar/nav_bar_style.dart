import 'package:flutter/material.dart';

import '../../themes/notebook/notebook_leather_surface.dart';
import '../../themes/notebook/notebook_visuals.dart';
import '../../themes/surface_palette.dart';
import 'nav_bar_metrics.dart';

/// Оформление нижней панели. Только внешний вид: ни размеров, ни поведения.
///
/// Панель — не страница, поэтому она не носит бумажную фактуру: она читается
/// как обложка, на которой открытый блокнот лежит.
@immutable
class NavBarStyle {
  const NavBarStyle({
    required this.gradient,
    required this.surface,
    required this.borderColor,
    required this.shadowColor,
    required this.wearsLeather,
  });

  factory NavBarStyle.of(BuildContext context) {
    final palette = AppSurfacePalette.of(context);
    return NavBarStyle(
      gradient: palette.navigationGradient,
      surface: palette.navigationSurface,
      borderColor: palette.borderStart.withValues(
        alpha: NavBarMetrics.topBorderOpacity,
      ),
      shadowColor: Colors.black.withValues(
        alpha: NavBarMetrics.shadowOpacity,
      ),
      wearsLeather: NotebookVisuals.maybeOf(context) != null,
    );
  }

  final Gradient gradient;
  final Color surface;
  final Color borderColor;
  final Color shadowColor;
  final bool wearsLeather;

  BoxDecoration get decoration => BoxDecoration(
        gradient: gradient,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: NavBarMetrics.topBorderWidth,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: NavBarMetrics.shadowBlur,
            offset: NavBarMetrics.shadowOffset,
          ),
        ],
      );

  /// Накладывает фактуру обложки. Плоский цвет под ней держит панель
  /// читаемой, пока изображение ещё не готово.
  Widget wrap(Widget child) {
    if (!wearsLeather) return child;
    return NotebookLeatherSurface(
      color: surface,
      lightweight: true,
      child: child,
    );
  }
}
