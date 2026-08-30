import 'package:flutter/widgets.dart';

/// Кнопка панели оболочки — то, что верхняя и нижняя панели рисуют.
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
    this.enabled = true,
  });

  /// Стабильный ключ. Панель добавляет свой префикс, поэтому тесты находят
  /// кнопку по смыслу, а не по порядковому номеру.
  final String id;
  final IconData icon;
  final String label;
  final bool enabled;
}
