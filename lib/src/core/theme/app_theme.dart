import 'package:flutter/material.dart';

import 'app_surface_palette.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final seed = isDark ? const Color(0xFFE47A57) : const Color(0xFFD87352);
  final background = isDark ? const Color(0xFF000000) : const Color(0xFFF4F1EB);
  final surface = isDark ? const Color(0xFF2B2E2A) : const Color(0xFFFFFDF9);
  final surfaceLow = isDark ? const Color(0xFF242622) : const Color(0xFFF8F5EF);
  final surfaceContainer =
      isDark ? const Color(0xFF2B2E2A) : const Color(0xFFF0ECE4);
  final surfaceHigh =
      isDark ? const Color(0xFF333632) : const Color(0xFFE6E1D8);
  final surfaceAlt = isDark ? const Color(0xFF333632) : const Color(0xFFDAD7CF);
  final border = isDark ? const Color(0xFF555B53) : const Color(0xFFAFAAA0);
  final onSurface = isDark ? const Color(0xFFF5F2EC) : const Color(0xFF282722);
  final secondary = isDark ? const Color(0xFFC9C5BE) : const Color(0xFF69655E);
  final onPrimary = isDark ? const Color(0xFF1B0D08) : const Color(0xFFFFFFFF);
  final palette = AppSurfacePalette(
    backgroundStart: background,
    backgroundEnd: isDark ? const Color(0xFF12100F) : const Color(0xFFE9E4DB),
    navigationSurface:
        isDark ? const Color(0xFF252825) : const Color(0xFFFFFDF9),
    panelSurface: surface,
    raisedSurface: surfaceHigh,
    nestedSurface: isDark ? const Color(0xFF3A3D39) : const Color(0xFFE6E1D8),
    calendarTile: isDark ? const Color(0xFF2B2E2A) : const Color(0xFFDAD7CF),
    weekdaySurface: isDark ? const Color(0xFF333632) : const Color(0xFFCBC8C0),
    borderStart: isDark ? const Color(0xFF626860) : const Color(0xFFA7A197),
    borderEnd: isDark ? const Color(0xFF41443F) : const Color(0xFFD3CEC5),
    accentStart: seed,
    accentEnd: isDark ? const Color(0xFFBF543B) : const Color(0xFFB9553D),
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  ).copyWith(
    primary: seed,
    onPrimary: onPrimary,
    primaryContainer:
        isDark ? const Color(0xFF4B2A21) : const Color(0xFFF2D9CF),
    onPrimaryContainer:
        isDark ? const Color(0xFFFFDACE) : const Color(0xFF522014),
    surface: surface,
    surfaceContainerLowest:
        isDark ? const Color(0xFF242622) : const Color(0xFFFFFFFF),
    surfaceContainerLow: surfaceLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceAlt,
    outline: border,
    outlineVariant: border,
    onSurface: onSurface,
    onSurfaceVariant: secondary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: background,
    disabledColor: isDark ? const Color(0xFF9C9992) : const Color(0xFF8A857D),
    extensions: [palette],
    fontFamily: 'Manrope',
    dividerTheme: DividerThemeData(
      color: border,
      thickness: 1,
      space: 1,
    ),
    textTheme: (isDark ? ThemeData.dark() : ThemeData.light())
        .textTheme
        .apply(
          fontFamily: 'Manrope',
          bodyColor: onSurface,
          displayColor: onSurface,
        )
        .copyWith(
          headlineLarge: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          headlineSmall: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          titleSmall: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelMedium: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          labelSmall: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: onSurface,
        fontFamily: 'Manrope',
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: palette.navigationSurface,
      indicatorColor:
          isDark ? const Color(0xFF4B2A21) : const Color(0xFFF0D8CF),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'Manrope',
          letterSpacing: 0,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? seed : secondary,
          size: 22,
        );
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: palette.panelSurface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.panelSurface,
      labelStyle: TextStyle(
        color: secondary,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: secondary,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: seed, width: 1.4),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: seed,
      selectionColor: const Color(0x667D4A39),
      selectionHandleColor: seed,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: border),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? seed : surfaceAlt;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? onPrimary : secondary;
      }),
      trackOutlineColor: WidgetStateProperty.all(border),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 3,
      focusElevation: 3,
      hoverElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: secondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        color: onSurface,
        fontFamily: 'Manrope',
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(
        color: secondary,
        fontFamily: 'Manrope',
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.panelSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.panelSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.panelSurface,
      modalBackgroundColor: palette.panelSurface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: palette.panelSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: palette.panelSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      dayPeriodShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF333632) : const Color(0xFF3F3A35),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
