import 'package:flutter/material.dart';

import '../../themes/screen/screen_panel.dart';
import '../../themes/screen/screen_visuals.dart';
import 'app_navigation_panel.dart';
import 'app_navigation_items.dart';
import 'nav_bar_item.dart';
import 'nav_bar_metrics.dart';
import 'screen_tool_bar.dart';

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
  static double heightOf(BuildContext context) {
    if (ScreenVisuals.maybeOf(context) == null) {
      return NavBarMetrics.toolHeight;
    }
    return ScreenToolBar.height +
        ScreenPanel.inset * 1.5 +
        MediaQuery.paddingOf(context).top;
  }

  @override
  Widget build(BuildContext context) {
    final screen = ScreenVisuals.maybeOf(context);

    if (screen != null) {
      return ScreenToolBar(
        items: items,
        colors: screen.colors,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
      );
    }

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
