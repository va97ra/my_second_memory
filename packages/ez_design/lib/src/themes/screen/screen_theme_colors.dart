import 'package:flutter/material.dart';

/// Значения одной темы-экрана.
///
/// Тема-экран — это не бумага, а подсвеченная панель на тёмном фоне. Таких
/// тем несколько («Космос», «Киберпанк»), и различаются они только этими
/// значениями: раскладку, формы и размеры они делят на всех. Новая тема
/// добавляется одним `const`-объектом, а не копией сборщика.
/// Чем отмечена выбранная кнопка панели навигации.
enum ScreenNavIndicator {
  /// Подложка под значком — плитка того же цвета, что и подпись.
  pill,

  /// Полоса под подписью. Значок и подпись при этом красятся акцентом сами.
  underline,
}

/// Как тема носит панели инструментов и навигации.
enum ScreenPanelStyle {
  /// Полоса матового стекла с полями по краям: сквозь неё виден задник, и
  /// она читается стеклом, лежащим на нём.
  floating,

  /// Панель во всю ширину, приклеенная к краю окна, — как в блокноте край
  /// обложки. Задник обходит её и светится вокруг экрана.
  edge,
}

@immutable
class ScreenThemeColors {
  const ScreenThemeColors({
    required this.brightness,
    required this.panels,
    required this.navIndicator,
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
    required this.today,
    required this.glow,
    required this.glint,
    required this.glassLights,
    required this.event,
    required this.task,
    required this.family,
    required this.purchase,
    required this.shift,
    required this.holiday,
    required this.toolTints,
    required this.backdrop,
  });

  /// Светлая тема-экран или тёмная. От неё зависят не только цвета: на
  /// светлой сегодняшний день красят подложкой, на тёмной — цветной шапкой,
  /// потому что подмешанный к тёмной плитке акцент даёт грязное пятно.
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  /// Вид панелей. От него зависит и то, как выглядят кнопки инструментов:
  /// в плавающей полосе они без рамок, у приклеенной панели — отдельными
  /// карточками.
  final ScreenPanelStyle panels;

  /// Чем отмечен открытый раздел в нижней панели.
  final ScreenNavIndicator navIndicator;

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

  /// Отметка сегодняшнего дня. Отдельно от акцента: акцентом красят то, что
  /// выбрал человек, а сегодня выбирает календарь.
  final Color today;

  /// Свечение вокруг сегодняшнего дня и под выбранной кнопкой панели.
  final Color glow;

  /// Свет, который идёт с задника и проходит через ребро стеклянной плитки.
  ///
  /// Не белый: свет у каждой темы свой — тёплый от планет, холодный от неона.
  /// Ребро, подсвеченное чужим светом, выдаёт стекло накладкой.
  final Color glint;

  /// Цветные источники, которые отражаются в стекле темы.
  ///
  /// Пустой список оставляет нейтральное стекло. Несколько цветов дают
  /// разнесённые по пластине блики, как от вывесок вокруг неё; сами виджеты
  /// не должны знать, к какой теме относятся эти источники.
  final List<Color> glassLights;

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

  /// Задник темы или null, если его нет: тогда фон заливается переходом от
  /// [backgroundStart] к [backgroundEnd].
  ///
  ///
  /// Не бесшовная текстура, а готовый кадр — светящаяся рамка по краям и
  /// пустая середина. Поэтому он растягивается по `cover` и на широком окне
  /// теряет края: рисунок там по краям и есть. Экран под ним всё равно залит
  /// цветом фона, так что не доехавшая картинка ничего не ломает.
  final String? backdrop;
}
