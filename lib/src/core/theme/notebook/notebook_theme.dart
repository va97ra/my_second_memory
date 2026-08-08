import 'package:flutter/material.dart';

import '../app_surface_palette.dart';
import '../app_theme.dart';
import 'notebook_visuals.dart';

ThemeData buildNotebookTheme() {
  const primary = Color(0xFFF4512A);
  const primaryDark = Color(0xFFB92B16);
  const ink = Color(0xFF201712);
  const mutedInk = Color(0xFF604B3F);
  const paper = Color(0xFFFFF0CD);
  const raisedPaper = Color(0xFFFFDFA3);
  const border = Color(0xFF824A28);
  const palette = AppSurfacePalette(
    backgroundStart: Color(0xFFC98D57),
    backgroundEnd: Color(0xFF96572F),
    navigationSurface: Color(0xFFFFE3AE),
    panelSurface: paper,
    raisedSurface: raisedPaper,
    nestedSurface: Color(0xFFF5CA83),
    calendarTile: Color(0xFFFFDFA0),
    weekdaySurface: Color(0xFFF0BE68),
    borderStart: Color(0xFFD09055),
    borderEnd: Color(0xFF75401F),
    accentStart: primary,
    accentEnd: primaryDark,
  );
  const visuals = NotebookVisuals(
    paper: paper,
    ink: ink,
    mutedInk: mutedInk,
    line: Color(0x4A4C789E),
    primaryTop: Color(0xFFFF7F57),
    primaryBottom: primaryDark,
    primaryShadow: Color(0xFF6F1B0D),
    blue: Color(0xFF1479D4),
    green: Color(0xFF0B9A5A),
    teal: Color(0xFF008E83),
    yellow: Color(0xFFE5A20A),
  );

  final base = buildAppTheme(brightness: Brightness.light);
  final scheme = base.colorScheme.copyWith(
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFFC3A6),
    onPrimaryContainer: const Color(0xFF4B160C),
    secondary: const Color(0xFF1479D4),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFC5E2FF),
    onSecondaryContainer: const Color(0xFF062B55),
    tertiary: const Color(0xFF008E83),
    onTertiary: Colors.white,
    surface: paper,
    surfaceContainerLowest: const Color(0xFFFFF7E5),
    surfaceContainerLow: const Color(0xFFFFE9BF),
    surfaceContainer: raisedPaper,
    surfaceContainerHigh: const Color(0xFFF5CA83),
    surfaceContainerHighest: const Color(0xFFEAB75E),
    outline: border,
    outlineVariant: const Color(0xFFB97843),
    onSurface: ink,
    onSurfaceVariant: mutedInk,
  );

  final strongButton = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return const Color(0xFFB79B83);
      }
      if (states.contains(WidgetState.pressed)) {
        return primaryDark;
      }
      return primary;
    }),
    foregroundColor: WidgetStateProperty.all(Colors.white),
    shadowColor: WidgetStateProperty.all(visuals.primaryShadow),
    elevation: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return 0;
      }
      return states.contains(WidgetState.pressed) ? 1 : 7;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      return BorderSide(
        color: states.contains(WidgetState.pressed)
            ? visuals.primaryShadow
            : const Color(0xFFFFA17F),
        width: 1.2,
      );
    }),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textStyle: WidgetStateProperty.all(
      const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    ),
  );

  return base.copyWith(
    colorScheme: scheme,
    canvasColor: const Color(0xFFA96535),
    disabledColor: const Color(0xFF9D816F),
    extensions: const [palette, visuals],
    appBarTheme: base.appBarTheme.copyWith(foregroundColor: ink),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFB97843),
      thickness: 1,
      space: 1,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: paper,
      elevation: 5,
      shadowColor: const Color(0x66000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: strongButton),
    elevatedButtonTheme: ElevatedButtonThemeData(style: strongButton),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed)
              ? const Color(0xFFEAB75E)
              : raisedPaper;
        }),
        foregroundColor: WidgetStateProperty.all(ink),
        elevation: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed) ? 0 : 4;
        }),
        shadowColor: WidgetStateProperty.all(const Color(0x66000000)),
        side: WidgetStateProperty.all(const BorderSide(color: border)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: base.iconButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed)
              ? const Color(0xFFE4AD53)
              : raisedPaper;
        }),
        foregroundColor: WidgetStateProperty.all(ink),
        side: WidgetStateProperty.all(const BorderSide(color: border)),
        elevation: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed) ? 0 : 4;
        }),
        shadowColor: WidgetStateProperty.all(const Color(0x66000000)),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: const Color(0xEFFFF0CD),
      labelStyle: const TextStyle(
        color: mutedInk,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: mutedInk,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: palette.navigationSurface,
      indicatorColor: const Color(0xFFF0643F),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? Colors.white : ink,
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: ink,
          fontFamily: 'Manrope',
          fontSize: 11.5,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w900
              : FontWeight.w700,
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? primary
            : const Color(0xFFC9A474);
      }),
      thumbColor: WidgetStateProperty.all(const Color(0xFFFFF7E5)),
      trackOutlineColor: WidgetStateProperty.all(border),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: paper,
      shadowColor: const Color(0x77000000),
      elevation: 8,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: paper,
      shadowColor: const Color(0x88000000),
      elevation: 10,
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: paper,
      modalBackgroundColor: paper,
      shadowColor: const Color(0x88000000),
      elevation: 12,
    ),
  );
}
