import 'package:flutter/material.dart';

/// Значения одной темы-экрана.
///
/// Тема-экран — это не бумага, а подсвеченная панель на тёмном фоне. Таких
/// тем несколько («Космос», «Киберпанк»), и различаются они только этими
/// значениями: раскладку, формы и размеры они делят на всех. Новая тема
/// добавляется одним `const`-объектом, а не копией сборщика.
@immutable
class ScreenThemeColors {
  const ScreenThemeColors({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.navigation,
    required this.panel,
    required this.raised,
    required this.nested,
    required this.tile,
    required this.weekday,
    required this.border,
    required this.divider,
    required this.ink,
    required this.mutedInk,
    required this.dimInk,
    required this.accent,
    required this.accentDeep,
    required this.onAccent,
    required this.glow,
    required this.event,
    required this.task,
    required this.family,
    required this.purchase,
    required this.shift,
    required this.holiday,
    required this.toolTints,
  });

  /// Фон страницы: сверху темнее, снизу глубже — свет идёт из верхнего угла.
  final Color backgroundStart;
  final Color backgroundEnd;

  /// Панели навигации сверху и снизу.
  final Color navigation;

  /// Карточка, лист, всплывающее меню.
  final Color panel;
  final Color raised;
  final Color nested;

  /// Ячейка дня в сетке месяца и полоска дней недели над ней.
  final Color tile;
  final Color weekday;

  final Color border;
  final Color divider;

  final Color ink;
  final Color mutedInk;

  /// Числа дней соседних месяцев: видно, что день есть, но он не этот.
  final Color dimInk;

  final Color accent;
  final Color accentDeep;
  final Color onAccent;

  /// Свечение вокруг сегодняшнего дня и под выбранной кнопкой панели.
  final Color glow;

  /// Цвета записей. Имена по смыслу записи, а не по цвету: в киберпанке те же
  /// роли красятся неоном, и «синий» перестал бы быть синим.
  final Color event;
  final Color task;
  final Color family;
  final Color purchase;
  final Color shift;
  final Color holiday;

  /// Цвета кнопок инструментов сверху, по порядку кнопок. Инструментов три,
  /// и каждый узнаётся по своему цвету раньше, чем прочитана подпись; если
  /// инструментов станет больше, цвета пойдут по кругу.
  final List<Color> toolTints;
}
