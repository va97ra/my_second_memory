import 'package:flutter/material.dart';

import '../../themes/screen/screen_panel.dart';
import '../../themes/screen/screen_theme_colors.dart';
import '../../themes/screen/screen_visuals.dart';
import 'app_navigation_panel.dart';
import 'app_navigation_items.dart';
import 'nav_bar_item.dart';
import 'nav_bar_metrics.dart';

/// Нижняя панель приложения.
///
/// Рисует ровно то, что ей передали: список кнопок и номер выбранной. Панель
/// не знает ни про маршруты, ни про вкладки, ни про то, что какая-то кнопка
/// особенная — поэтому добавление кнопки её не меняет.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<NavBarItem> items;

  /// Индекс подсвеченной кнопки в [items], либо null у верхнего инструмента.
  final int? selectedIndex;

  /// Вызывается с индексом нажатой кнопки.
  final ValueChanged<int> onSelected;

  /// Сколько места панель займёт в этой теме.
  static double heightOf(BuildContext context) {
    final screen = ScreenVisuals.maybeOf(context);
    if (screen?.colors.panels != ScreenPanelStyle.floating) {
      return NavBarMetrics.bottomContentExtent;
    }
    return NavBarMetrics.bottomContentExtent + ScreenPanel.inset * 1.5;
  }

  @override
  Widget build(BuildContext context) {
    final screen = ScreenVisuals.maybeOf(context);
    final content = Padding(
      padding: NavBarMetrics.padding,
      child: SizedBox(
        height: NavBarMetrics.height,
        child: AppNavigationItems(
          items: items,
          selectedIndex: selectedIndex?.clamp(0, items.length - 1),
          onSelected: onSelected,
          keyPrefix: 'bottom',
          compact: false,
        ),
      ),
    );

    // Панель экранной темы лежит на заднике отдельной полосой; блокнотная —
    // край обложки, и от края окна ей отступать некуда.
    if (screen?.colors.panels == ScreenPanelStyle.floating) {
      return ScreenPanel(
        colors: screen!.colors,
        edge: VerticalDirection.down,
        child: content,
      );
    }
    return AppNavigationPanel(
      edge: NavigationPanelEdge.bottom,
      child: content,
    );
  }
}
