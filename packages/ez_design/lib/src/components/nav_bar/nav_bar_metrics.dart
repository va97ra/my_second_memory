import 'package:flutter/widgets.dart';

/// Размеры нижней панели. Только числа: ни цветов, ни поведения.
abstract final class NavBarMetrics {
  /// Панель — не страница, она не листается и не тянется: высота постоянна.
  static const double height = 64;

  /// Поля вокруг ряда кнопок. Снизу больше, чем сверху: под ним ещё идёт
  /// системная безопасная зона.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(8, 2, 8, 4);

  /// Ниже этого касание перестаёт быть надёжным.
  static const double minimumTouchTarget = 48;

  /// Тень, которой панель приподнята над страницей.
  static const double shadowBlur = 22;
  static const Offset shadowOffset = Offset(0, -8);
  static const double shadowOpacity = 0.24;

  /// Толщина линии, отделяющей панель от страницы.
  static const double topBorderWidth = 1;
  static const double topBorderOpacity = 0.78;
}
