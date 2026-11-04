import 'package:flutter/material.dart';

import 'app_navigation_panel.dart';
import 'app_navigation_items.dart';
import 'nav_bar_item.dart';
import 'nav_bar_metrics.dart';

/// Верхняя панель быстрых инструментов в том же материале, что нижняя.
class AppToolBar extends StatelessWidget {
  const AppToolBar({
    required this.items,
    required this.onSelected,
    this.selectedIndex,
    super.key,
  });

  final List<NavBarItem> items;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  /// Сколько места панель займёт в этой теме. Спрашивает оболочка: слот под
  /// панель она отводит до того, как панель построится.
  ///
  /// Полоса экранной темы отступает от краёв и от системной строки сама,
  /// поэтому её поля входят в высоту слота.
  static double heightOf(BuildContext context) => NavBarMetrics.toolHeight;

  @override
  Widget build(BuildContext context) {
    return AppNavigationPanel(
      edge: NavigationPanelEdge.top,
      child: SizedBox(
          height: NavBarMetrics.toolHeight,
          child: AppNavigationItems(
            items: items,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            keyPrefix: 'top',
            compact: true,
          ),
      ),
    );
  }
}
