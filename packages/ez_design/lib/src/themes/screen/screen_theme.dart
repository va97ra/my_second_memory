import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../app_theme_style.dart';
import '../surface_palette.dart';
import 'cosmos_colors.dart';
import 'cyberpunk_colors.dart';
import 'screen_theme_colors.dart';
import 'screen_visuals.dart';

/// Собирает тему-экран из её значений.
///
/// Собран поверх плоской тёмной темы: у неё уже настроены поля, меню, кнопки
/// и размеры шрифтов, и переписывать их ради цвета незачем. Отсюда уходят
/// древесные текстуры — экран не бумага и не лежит на столе.
ThemeData buildScreenTheme(ScreenThemeColors c) {
  final base = buildAppTheme(brightness: Brightness.dark);
  final palette = AppSurfacePalette(
    backgroundStart: c.backgroundStart,
    backgroundEnd: c.backgroundEnd,
    navigationSurface: c.navigation,
    panelSurface: c.panel,
    raisedSurface: c.raised,
    nestedSurface: c.nested,
    calendarTile: c.tile,
    weekdaySurface: c.weekday,
    borderStart: c.border,
    borderEnd: c.divider,
    accentStart: c.accent,
    accentEnd: c.accentDeep,
  );
  final scheme = base.colorScheme.copyWith(
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.accentDeep,
    onPrimaryContainer: c.ink,
    secondary: c.event,
    onSecondary: Colors.white,
    secondaryContainer: c.purchase,
    onSecondaryContainer: c.ink,
    tertiary: c.shift,
    onTertiary: Colors.white,
    surface: c.panel,
    surfaceContainerLowest: c.backgroundStart,
    surfaceContainerLow: c.tile,
    surfaceContainer: c.panel,
    surfaceContainerHigh: c.raised,
    surfaceContainerHighest: c.nested,
    outline: c.border,
    outlineVariant: c.divider,
    onSurface: c.ink,
    onSurfaceVariant: c.mutedInk,
    error: c.holiday,
  );

  return base.copyWith(
    colorScheme: scheme,
    canvasColor: c.backgroundStart,
    disabledColor: c.dimInk,
    dividerTheme: base.dividerTheme.copyWith(color: c.divider),
    // Выбранная кнопка панели красится акцентом темы. Плоская основа
    // держит там терракоту, и в киберпанке она оставалась единственным
    // тёплым пятном на весь экран.
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: c.navigation,
      indicatorColor: Color.alphaBlend(
        c.accent.withValues(alpha: 0.22),
        c.panel,
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? c.accent : c.mutedInk,
          size: selected ? 24 : 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontFamily: 'Manrope',
          letterSpacing: 0,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
          color: selected ? c.accent : c.mutedInk,
        );
      }),
    ),
    // Стрелки месяца, «сегодня» и «назад» сидят в своих плитках. Без них
    // значок на тёмном фоне не читается кнопкой — не видно, где нажимать.
    iconButtonTheme: IconButtonThemeData(
      style: base.iconButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed) ? c.nested : c.panel;
        }),
        foregroundColor: WidgetStatePropertyAll(c.ink),
        side: WidgetStatePropertyAll(BorderSide(color: c.border)),
      ),
    ),
    // Расширения перечислены целиком, а не добавлены к чужим: плоская тема
    // кладёт древесную текстуру, и оставить её здесь значило бы положить
    // экран на деревянный стол.
    extensions: [palette, ScreenVisuals(c)],
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
  );
}

/// Значения темы-экрана или null, если тема блокнотная.
///
/// Одно место, где перечислены экранные темы: и сборка темы, и её образец в
/// настройках спрашивают отсюда, а не держат каждый свой список.
ScreenThemeColors? screenColorsOf(AppThemeStyle style) => switch (style) {
      AppThemeStyle.cosmos => cosmosColors,
      AppThemeStyle.cyberpunk => cyberpunkColors,
      AppThemeStyle.notebookLight || AppThemeStyle.notebookDark => null,
    };
