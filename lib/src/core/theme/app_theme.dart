import 'package:flutter/material.dart';

import 'app_surface_palette.dart';
import 'app_surface_textures.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final seed = isDark ? const Color(0xFFFF6A3D) : const Color(0xFFF05A30);
  final accentEnd = isDark ? const Color(0xFFC9361E) : const Color(0xFFB72F1B);
  final secondaryAccent =
      isDark ? const Color(0xFF39C3D5) : const Color(0xFF087C8C);
  final tertiaryAccent =
      isDark ? const Color(0xFF2AC495) : const Color(0xFF087A62);
  final background = isDark ? const Color(0xFF07090D) : const Color(0xFFF6F4EF);
  final surface = isDark ? const Color(0xFF1D252E) : const Color(0xFFFFFDFA);
  final surfaceLow = isDark ? const Color(0xFF161C23) : const Color(0xFFF8F6F1);
  final surfaceContainer =
      isDark ? const Color(0xFF202A34) : const Color(0xFFF2EEE6);
  final surfaceHigh =
      isDark ? const Color(0xFF27333F) : const Color(0xFFEEEAE0);
  final surfaceAlt = isDark ? const Color(0xFF303E4B) : const Color(0xFFE5E0D3);
  final border = isDark ? const Color(0xFF526272) : const Color(0xFFA8A192);
  final onSurface = isDark ? const Color(0xFFF7F9FC) : const Color(0xFF231F1A);
  final secondary = isDark ? const Color(0xFFBCC7D2) : const Color(0xFF6E6559);
  final onPrimary = isDark ? const Color(0xFF260B04) : const Color(0xFFFFFFFF);
  final palette = AppSurfacePalette(
    backgroundStart: background,
    backgroundEnd: isDark ? const Color(0xFF151018) : const Color(0xFFEDE9DE),
    navigationSurface:
        isDark ? const Color(0xFF161C23) : const Color(0xFFFCFAF6),
    panelSurface: surface,
    raisedSurface: surfaceHigh,
    nestedSurface: isDark ? const Color(0xFF303E4B) : const Color(0xFFE5E0D3),
    calendarTile: isDark ? const Color(0xFF202A34) : const Color(0xFFF2EEE4),
    weekdaySurface: isDark ? const Color(0xFF2A3642) : const Color(0xFFE8E2D2),
    borderStart: isDark ? const Color(0xFF718397) : const Color(0xFF96907F),
    borderEnd: isDark ? const Color(0xFF344351) : const Color(0xFFDDD8C8),
    accentStart: seed,
    accentEnd: accentEnd,
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  ).copyWith(
    primary: seed,
    onPrimary: onPrimary,
    primaryContainer:
        isDark ? const Color(0xFF572315) : const Color(0xFFFFD7CA),
    onPrimaryContainer:
        isDark ? const Color(0xFFFFDACC) : const Color(0xFF4B1408),
    secondary: secondaryAccent,
    onSecondary: isDark ? const Color(0xFF001F25) : Colors.white,
    secondaryContainer:
        isDark ? const Color(0xFF123D46) : const Color(0xFFC9F2F6),
    onSecondaryContainer:
        isDark ? const Color(0xFFBFF6FF) : const Color(0xFF07353C),
    tertiary: tertiaryAccent,
    onTertiary: isDark ? const Color(0xFF00251A) : Colors.white,
    surface: surface,
    surfaceContainerLowest:
        isDark ? const Color(0xFF11171D) : const Color(0xFFFFFFFF),
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
    disabledColor: isDark ? const Color(0xFF84909B) : const Color(0xFF71808A),
    extensions: [
      palette,
      isDark ? AppSurfaceTextures.dark : AppSurfaceTextures.light,
    ],
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
          isDark ? const Color(0xFF572315) : const Color(0xFFFFD7CA),
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
          size: selected ? 24 : 22,
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
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.36 : 0.16),
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
      selectionColor: seed.withValues(alpha: 0.34),
      selectionHandleColor: seed,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return surfaceAlt;
          if (states.contains(WidgetState.pressed)) return accentEnd;
          return seed;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled) ? secondary : onPrimary;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return 0;
          return states.contains(WidgetState.pressed) ? 1 : 5;
        }),
        shadowColor: WidgetStatePropertyAll(
          accentEnd.withValues(alpha: isDark ? 0.68 : 0.42),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.disabled)
                ? border
                : Color.lerp(seed, Colors.white, 0.34)!,
            width: 1,
          );
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
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
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: seed,
      foregroundColor: onPrimary,
      elevation: 6,
      focusElevation: 6,
      hoverElevation: 8,
      splashColor: secondaryAccent.withValues(alpha: 0.22),
      shape: const RoundedRectangleBorder(
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
      backgroundColor: surfaceHigh,
      contentTextStyle: TextStyle(color: onSurface, fontFamily: 'Manrope'),
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
        color: isDark ? const Color(0xFF27333F) : const Color(0xFF24313A),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
