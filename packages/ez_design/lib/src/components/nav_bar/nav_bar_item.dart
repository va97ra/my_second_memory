import 'package:flutter/widgets.dart';

/// Кнопка нижней панели — то, что панель рисует.
///
/// Здесь нет ни маршрута, ни ветки, ни условий: панель не знает, что случится
/// по нажатию, и потому не растёт от каждой новой кнопки. Куда ведёт кнопка,
/// решает приложение.
@immutable
class NavBarItem {
  const NavBarItem({
    required this.id,
    required this.icon,
    required this.label,
  });

  /// Стабильный ключ. Панель делает из него `ValueKey('bottom_$id')`, поэтому
  /// тесты находят кнопку по смыслу, а не по порядковому номеру.
  final String id;
  final IconData icon;
  final String label;
}
