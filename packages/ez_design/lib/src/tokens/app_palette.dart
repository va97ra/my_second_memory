import 'package:flutter/painting.dart';

/// Все цвета приложения, которые не зависят от темы. Экраны берут цвет отсюда по
/// имени и своих не заводят: сменить цвет значит поправить одну строку.
abstract final class AppPalette {
  // Сочные: выбор владельца от 4 ноября 2026.
  static const magenta = Color(0xFFFF2E93);
  static const magentaDeep = Color(0xFFC4146B);
  static const magentaLight = Color(0xFFFF5CAC);
  static const magentaShadow = Color(0xFF7A0B43);
  static const magentaTint = Color(0xFFFFD1E6);
  static const magentaInk = Color(0xFF4D0429);
  static const cyan = Color(0xFF00E5FF);
  static const amber = Color(0xFFFFB000);
  static const amberDeep = Color(0xFF9A5B00);
  static const violet = Color(0xFFB45CFF);
  static const violetDeep = Color(0xFF7A1FD1);
  static const turquoise = Color(0xFF19E3D0);
  static const orange = Color(0xFFFF7A00);
  static const indigo = Color(0xFF3D5BFF);

  // Смысл: экран спрашивает, что это значит, а не какого оно цвета.
  static const accent = magenta;
  static const account = indigo;
  static const weekend = magenta;
  static const shortenedDay = amber;

  /// Водяной знак на закрашенной плитке дня: темнее её заливки, но не спорит с числом.
  static const dayStamp = Color(0x33000000);
  static const today = cyan;

  /// Отметка сегодня на светлой коже: голубой на ней теряется.
  static const todayOnLight = indigo;
  static const success = Color(0xFF12A150);
  static const successTint = Color(0xFFBFE8C9);
  static const danger = Color(0xFFFF3B55);
  static const dangerDeep = Color(0xFFB00F35);
  static const warning = amberDeep;
  static const done = Color(0xFF6B7280);
  static const muted = Color(0xFF94A3B8);

  // Светлая бумага: карточки и дни во всех темах.
  static const paper = Color(0xFFF7F5EF);
  static const paperDay = Color(0xFFF3F1EA);
  static const paperInk = Color(0xFF16141A);

  // Чёрная кожа тёмной темы.
  static const black = Color(0xFF0B0B0E);
  static const blackDeep = Color(0xFF050506);
  static const blackRaised = Color(0xFF1E1E24);
  static const blackPressed = Color(0xFF2A2A32);
  static const blackNested = Color(0xFF16161B);
  static const blackBorder = Color(0xFF3A3A44);
  static const blackBorderSoft = Color(0xFF2A2A32);
  static const blackDisabled = Color(0xFF4A4A55);
  static const blackInput = Color(0xEF16161B);
  static const onBlack = Color(0xFFF6F6FA);
  static const onBlackMuted = Color(0xFFA0A2AE);
  static const onBlackDisabled = Color(0xFF6E6E7A);

  // Серебристая кожа светлой темы.
  static const silver = Color(0xFFBABECA);
  static const silverLight = Color(0xFFC4C8D3);
  static const silverRaised = Color(0xFFCDD0DA);
  static const silverPale = Color(0xFFDCDEE5);
  static const silverDeep = Color(0xFFA9ADBA);
  static const silverBorder = Color(0xFF8C90A0);
  static const silverBorderDeep = Color(0xFF6F7383);
  static const silverInput = Color(0xEFF2F3F6);
  static const onSilverMuted = Color(0xFF4A4C57);
  static const onSilverDisabled = Color(0xFF6B6E7B);

  // Уровни поверхности: фон ниже всех, на нём карточка, поверх неё диалог. Каждый
  // следующий светлее: перепад и показывает глазу, что лежит сверху.
  static const blackCard = Color(0xFF1E1E24);
  static const blackDialog = Color(0xFF2A2A32);
  static const silverCard = Color(0xFFEDEFF3);
  static const silverDialog = Color(0xFFF7F8FA);

  // Лист для письма: там, где человек пишет, бумага с линейкой, а не кожа.
  static const writingPaper = paper;
  static const writingLine = Color(0x4A4C789E);

  // Лента отпуска: ткань и золотая нить.
  static const vacationCloth = Color(0xFF891C37);
  static const vacationThread = Color(0xFFD6A84B);
  static const vacationText = Color(0xFFFFE5A3);
  static const vacationTextShadow = Color(0xCC3A0713);

  // Праздничная лента.
  static const holidayThread = amber;

  // Тени и края.
  static const shadowSoft = Color(0x55000000);
  static const shadow = Color(0x66000000);
  static const shadowStrong = Color(0x88000000);
  static const glint = Color(0x55FFFFFF);
}
