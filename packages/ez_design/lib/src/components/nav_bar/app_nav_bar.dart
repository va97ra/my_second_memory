import 'package:flutter/material.dart';

import 'nav_bar_item.dart';
import 'nav_bar_metrics.dart';
import 'nav_bar_style.dart';

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

  /// Индекс подсвеченной кнопки в [items].
  final int selectedIndex;

  /// Вызывается с индексом нажатой кнопки.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final style = NavBarStyle.of(context);
    return DecoratedBox(
      decoration: style.decoration,
      child: style.wrap(
        SafeArea(
          top: false,
          child: Padding(
            padding: NavBarMetrics.padding,
            child: NavigationBar(
              height: NavBarMetrics.height,
              selectedIndex: selectedIndex.clamp(0, items.length - 1),
              onDestinationSelected: onSelected,
              destinations: [
                for (final item in items)
                  NavigationDestination(
                    key: ValueKey('bottom_${item.id}'),
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
