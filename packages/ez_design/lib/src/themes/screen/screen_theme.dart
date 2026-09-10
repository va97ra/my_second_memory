import 'dart:async';

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
  final base = buildAppTheme(brightness: c.brightness);
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
    brightness: c.brightness,
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
    // Умолчания Material дают светло-серую волну, и на тёмной теме она
    // читается вспышкой, а на стекле — белым пятном. Волна красится акцентом
    // темы: это отклик приложения, а не системы.
    splashColor: c.accent.withValues(alpha: 0.14),
    highlightColor: c.accent.withValues(alpha: 0.07),
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
          color: selected ? c.accent : _restingInk(c),
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
          color: selected ? c.accent : _restingInk(c),
        );
      }),
    ),
    // Поле ввода — вырез в пластине: сквозь него видно то, что лежит под
    // стеклом, а кромка выреза притенена. Поэтому поле не заливается своим
    // цветом, а слегка гасит фон под собой.
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Colors.black.withValues(alpha: c.isDark ? 0.22 : 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.12),
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.accent, width: 1.6),
      ),
    ),
    // Всплывающие листы — тоже стекло, и задаётся оно здесь, а не в каждом
    // из тринадцати мест, где такой лист открывают. Затемнение под ним
    // слабее обычного: за плотной шторкой сквозь стекло видно погашенный
    // экран, а не задник, и стекло перестаёт быть стеклом.
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: c.panel.withValues(alpha: c.isDark ? 0.86 : 0.76),
      modalBackgroundColor: c.panel.withValues(alpha: c.isDark ? 0.86 : 0.76),
      modalBarrierColor: Colors.black.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      // Светлая линия по краю — освещённая кромка пластины. Без неё лист
      // просто просвечивает, а стеклом не читается: у стекла видно, где оно
      // кончается.
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(
          color: c.glint.withValues(alpha: c.isDark ? 0.4 : 0.8),
          width: 1.2,
        ),
      ),
    ),
    // Кнопки плоской основы держат её терракоту числами, а не берут цвет
    // из схемы: в экранной теме главная кнопка оставалась оранжевой.
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        // Главная кнопка тоже стеклянная: сквозь неё чуть просвечивает то,
        // на чём она лежит. Сплошная заливка рядом со стеклянными соседями
        // читается наклейкой.
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return c.nested;
          if (states.contains(WidgetState.pressed)) {
            return c.accentDeep.withValues(alpha: 0.92);
          }
          return c.accent.withValues(alpha: 0.82);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? c.dimInk
              : c.onAccent;
        }),
        shadowColor: WidgetStatePropertyAll(
          c.accentDeep.withValues(alpha: 0.6),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: c.glint.withValues(alpha: 0.55), width: 1.2),
        ),
      ),
    ),
    // Полоса выбора режима без своего оформления приходит материаловской
    // сиреневой — единственным цветом в приложении, который ниоткуда.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? c.accent : c.panel;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? c.onAccent : c.ink;
        }),
        side: WidgetStatePropertyAll(BorderSide(color: c.border)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
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

/// Светлая тема или тёмная. У блокнотных яркость записана в самом
/// перечислении, у экранных — в их значениях: «Космос» светлый, «Киберпанк»
/// тёмный, и одного правила «всё, кроме светлого блокнота, тёмное» больше
/// не хватает.
Brightness brightnessOf(AppThemeStyle style) {
  final screen = screenColorsOf(style);
  if (screen != null) return screen.brightness;
  return style == AppThemeStyle.notebookLight
      ? Brightness.light
      : Brightness.dark;
}

/// Готовит задник темы к первому кадру.
///
/// Без этого картинка декодируется уже во время показа: первый кадр рисуется
/// одним переходом, следующий — с изображением, и это видно как моргание при
/// запуске и при смене темы. Ошибку глотаем: тема без задника обходится
/// переходом, и падать из-за картинки нечему.
Future<void> preloadScreenBackdrop(AppThemeStyle style) async {
  final backdrop = screenColorsOf(style)?.backdrop;
  if (backdrop == null) return;
  final completer = Completer<void>();
  final stream = AssetImage(backdrop).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, __) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    },
    onError: (_, __) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    },
  );
  stream.addListener(listener);
  await completer.future;
}

/// Цвет невыбранной кнопки панели.
///
/// Приглушённые чернила там читались серым пятном: разделы, в которых ты не
/// находишься, — это не второстепенный текст, а такие же кнопки. Берутся
/// обычные чернила, чуть отпущенные, чтобы выбранный раздел всё равно
/// выступал вперёд.
Color _restingInk(ScreenThemeColors c) =>
    c.ink.withValues(alpha: c.isDark ? 0.62 : 0.78);
