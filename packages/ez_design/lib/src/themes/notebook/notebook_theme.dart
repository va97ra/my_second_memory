import 'package:flutter/material.dart';

import '../surface_palette.dart';
import '../app_theme.dart';
import 'notebook_assets.dart';
import 'notebook_visuals.dart';

/// Every colour that separates the light notebook from the dark one.
///
/// Both notebooks are the same object under different light, so the shapes,
/// textures and terracotta accent stay put and only these values move.
@immutable
class _NotebookColors {
  const _NotebookColors({
    required this.brightness,
    required this.ink,
    required this.mutedInk,
    required this.paper,
    required this.raisedPaper,
    required this.pressedPaper,
    required this.border,
    required this.outlineVariant,
    required this.line,
    required this.deskStart,
    required this.deskEnd,
    required this.navigation,
    required this.nested,
    required this.weekday,
    required this.borderStart,
    required this.borderEnd,
    required this.containerLowest,
    required this.containerLow,
    required this.containerHigh,
    required this.containerHighest,
    required this.disabledButton,
    required this.disabled,
    required this.inputFill,
    required this.switchTrackOff,
    required this.switchThumb,
    required this.blue,
    required this.green,
    required this.teal,
    required this.yellow,
    required this.paperAsset,
    required this.leatherAsset,
  });

  final Brightness brightness;
  final Color ink;
  final Color mutedInk;
  final Color paper;
  final Color raisedPaper;
  final Color pressedPaper;
  final Color border;
  final Color outlineVariant;
  final Color line;
  final Color deskStart;
  final Color deskEnd;
  final Color navigation;
  final Color nested;
  final Color weekday;
  final Color borderStart;
  final Color borderEnd;
  final Color containerLowest;
  final Color containerLow;
  final Color containerHigh;
  final Color containerHighest;
  final Color disabledButton;
  final Color disabled;
  final Color inputFill;
  final Color switchTrackOff;
  final Color switchThumb;
  final Color blue;
  final Color green;
  final Color teal;
  final Color yellow;
  final String paperAsset;
  final String leatherAsset;
}

/// Terracotta reads on both papers, so the accent never moves.
const _primary = Color(0xFFC2492E);
const _primaryDark = Color(0xFF8E3520);

/// The colour of a sheet of the notebook. Cards and calendar day cells keep it
/// in both themes: they are loose paper lying on the book, not the book.
const notebookCardSurface = Color(0xFFF5F1E8);
const notebookCardInk = Color(0xFF201712);

const _lightColors = _NotebookColors(
  brightness: Brightness.light,
  ink: Color(0xFF201712),
  mutedInk: Color(0xFF604B3F),
  paper: notebookCardSurface,
  raisedPaper: Color(0xFFEDE7DA),
  pressedPaper: Color(0xFFD6CCB4),
  border: Color(0xFF6B4A34),
  outlineVariant: Color(0xFFA8875F),
  line: Color(0x4A4C789E),
  deskStart: Color(0xFF4A3728),
  deskEnd: Color(0xFF241811),
  navigation: Color(0xFFF3EFE5),
  nested: Color(0xFFE5DFCF),
  weekday: Color(0xFFDDD5C2),
  borderStart: Color(0xFF8A6A4D),
  borderEnd: Color(0xFF4A3323),
  containerLowest: Color(0xFFFAF7F0),
  containerLow: Color(0xFFF0EAD9),
  containerHigh: Color(0xFFE5DFCF),
  containerHighest: Color(0xFFDED5C0),
  disabledButton: Color(0xFFB79B83),
  disabled: Color(0xFF9C9285),
  inputFill: Color(0xEFF5F1E8),
  switchTrackOff: Color(0xFFC4B69A),
  switchThumb: Color(0xFFFFF7E5),
  blue: Color(0xFF1479D4),
  green: Color(0xFF0B9A5A),
  teal: Color(0xFF008E83),
  yellow: Color(0xFFE5A20A),
  paperAsset: NotebookAssets.paper,
  leatherAsset: NotebookAssets.leather,
);

const _darkColors = _NotebookColors(
  brightness: Brightness.dark,
  ink: Color(0xFFEDE6DA),
  mutedInk: Color(0xFFB3A695),
  paper: Color(0xFF2B2521),
  raisedPaper: Color(0xFF3A332C),
  pressedPaper: Color(0xFF4E443A),
  // Brighter than the light notebook's border: the same brown disappears
  // against a dark page.
  border: Color(0xFF8A6A4D),
  outlineVariant: Color(0xFF7A6248),
  line: Color(0x3A9BB6D6),
  deskStart: Color(0xFF1C1512),
  deskEnd: Color(0xFF0C0806),
  navigation: Color(0xFF262019),
  nested: Color(0xFF231E19),
  weekday: Color(0xFF3A332C),
  borderStart: Color(0xFF7A5B40),
  borderEnd: Color(0xFF3A281B),
  containerLowest: Color(0xFF211C18),
  containerLow: Color(0xFF262019),
  containerHigh: Color(0xFF443B32),
  containerHighest: Color(0xFF4E443A),
  disabledButton: Color(0xFF6B5A4C),
  disabled: Color(0xFF7A7167),
  inputFill: Color(0xEF2B2521),
  switchTrackOff: Color(0xFF5A4E42),
  switchThumb: Color(0xFFF0E7D8),
  blue: Color(0xFF4FA3E8),
  green: Color(0xFF35BA7C),
  teal: Color(0xFF31B0A4),
  yellow: Color(0xFFF0B93A),
  paperAsset: NotebookAssets.darkPaper,
  leatherAsset: NotebookAssets.darkLeather,
);

ThemeData buildNotebookTheme({Brightness brightness = Brightness.light}) {
  final c = brightness == Brightness.light ? _lightColors : _darkColors;
  const primary = _primary;
  const primaryDark = _primaryDark;
  final ink = c.ink;
  final mutedInk = c.mutedInk;
  final paper = c.paper;
  final raisedPaper = c.raisedPaper;
  final border = c.border;
  final palette = AppSurfacePalette(
    backgroundStart: c.deskStart,
    backgroundEnd: c.deskEnd,
    navigationSurface: c.navigation,
    panelSurface: paper,
    raisedSurface: raisedPaper,
    nestedSurface: c.nested,
    // Day cells are loose paper too.
    calendarTile: const Color(0xFFF0EBDF),
    weekdaySurface: c.weekday,
    borderStart: c.borderStart,
    borderEnd: c.borderEnd,
    accentStart: primary,
    accentEnd: primaryDark,
  );
  final visuals = NotebookVisuals(
    paper: paper,
    ink: ink,
    mutedInk: mutedInk,
    line: c.line,
    primaryTop: const Color(0xFFC97655),
    primaryBottom: primaryDark,
    primaryShadow: const Color(0xFF5A2415),
    blue: c.blue,
    green: c.green,
    teal: c.teal,
    yellow: c.yellow,
    paperAsset: c.paperAsset,
    leatherAsset: c.leatherAsset,
    cardSurface: notebookCardSurface,
    cardInk: notebookCardInk,
  );

  final base = buildAppTheme(brightness: brightness);
  final scheme = base.colorScheme.copyWith(
    brightness: brightness,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE8C4B0),
    onPrimaryContainer: const Color(0xFF3D160D),
    secondary: c.blue,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFC5E2FF),
    onSecondaryContainer: const Color(0xFF062B55),
    tertiary: c.teal,
    onTertiary: Colors.white,
    surface: paper,
    surfaceContainerLowest: c.containerLowest,
    surfaceContainerLow: c.containerLow,
    surfaceContainer: raisedPaper,
    surfaceContainerHigh: c.containerHigh,
    surfaceContainerHighest: c.containerHighest,
    outline: border,
    outlineVariant: c.outlineVariant,
    onSurface: ink,
    onSurfaceVariant: mutedInk,
  );

  final strongButton = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return c.disabledButton;
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
            : const Color(0xFFD9927A),
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
    // Бумага, а не стол: `canvasColor` — это фон выпадающих списков, и на
    // столе цвета кофе чернильный текст в них не читался. Фоны приложения
    // рисуются своими градиентами и на этот цвет не смотрят.
    canvasColor: paper,
    disabledColor: c.disabled,
    extensions: [palette, visuals],
    appBarTheme: base.appBarTheme.copyWith(foregroundColor: ink),
    dividerTheme: DividerThemeData(
      color: c.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: paper,
      elevation: 5,
      shadowColor: const Color(0x66000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: strongButton),
    elevatedButtonTheme: ElevatedButtonThemeData(style: strongButton),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed)
              ? c.containerHighest
              : raisedPaper;
        }),
        foregroundColor: WidgetStateProperty.all(ink),
        elevation: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed) ? 0 : 4;
        }),
        shadowColor: WidgetStateProperty.all(const Color(0x66000000)),
        side: WidgetStateProperty.all(BorderSide(color: border)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: base.iconButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed)
              ? c.pressedPaper
              : raisedPaper;
        }),
        foregroundColor: WidgetStateProperty.all(ink),
        side: WidgetStateProperty.all(BorderSide(color: border)),
        elevation: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed) ? 0 : 4;
        }),
        shadowColor: WidgetStateProperty.all(const Color(0x66000000)),
      ),
    ),
    // Stock segmented buttons arrive Material blue, the one accent in the app
    // that belongs to no material.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : raisedPaper;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? Colors.white : ink;
        }),
        side: WidgetStateProperty.all(BorderSide(color: border)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: c.inputFill,
      labelStyle: TextStyle(
        color: mutedInk,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(
        color: mutedInk,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      // The panel behind the bar carries the surface; an opaque bar would
      // paint over its grain.
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: primary,
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
            : c.switchTrackOff;
      }),
      thumbColor: WidgetStateProperty.all(c.switchThumb),
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
