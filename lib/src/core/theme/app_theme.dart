import 'package:flutter/material.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final seed = isDark ? const Color(0xFFD97757) : const Color(0xFFC56F50);
  final background = isDark ? const Color(0xFF20211F) : const Color(0xFFF0EEE8);
  final surface = isDark ? const Color(0xFF2B2C29) : const Color(0xFFF9F7F2);
  final surfaceAlt = isDark ? const Color(0xFF30312E) : const Color(0xFFEAE7DF);
  final border = isDark ? const Color(0xFF464743) : const Color(0xFFCEC9BE);
  final onSurface = isDark ? const Color(0xFFF0EEE7) : const Color(0xFF2B2925);
  final secondary = isDark ? const Color(0xFFC5C2BA) : const Color(0xFF68635B);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  ).copyWith(
    primary: seed,
    surface: surface,
    surfaceContainerHighest: surfaceAlt,
    outlineVariant: border,
    onSurface: onSurface,
    onSurfaceVariant: secondary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
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
          bodyMedium: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
      backgroundColor: surface,
      indicatorColor:
          isDark ? const Color(0xFF4A352D) : const Color(0xFFE8D7CD),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
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
      color: surface,
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
      fillColor: surface,
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
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
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
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: surface,
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
        color: isDark ? const Color(0xFF151613) : const Color(0xFF3F3A35),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
