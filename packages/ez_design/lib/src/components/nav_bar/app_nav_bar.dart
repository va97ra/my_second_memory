import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return AppNavigationPanel(
      edge: NavigationPanelEdge.bottom,
      child: Padding(
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
      ),
    );
  }
}
