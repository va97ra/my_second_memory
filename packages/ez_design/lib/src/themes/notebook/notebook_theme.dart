import 'package:flutter/material.dart';

import '../../tokens/app_palette.dart';

import '../../components/press_pulse.dart';
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
    required this.card,
    required this.dialog,
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

  /// Уровни поверхности над страницей: см. [AppPalette].
  final Color card;
  final Color dialog;
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

const _primary = AppPalette.accent;
const _primaryDark = AppPalette.magentaDeep;

/// The colour of a sheet of the notebook. Cards and calendar day cells keep it
/// in both themes: they are loose paper lying on the book, not the book.
const notebookCardSurface = AppPalette.paper;
const notebookCardInk = AppPalette.paperInk;

const _lightColors = _NotebookColors(
  brightness: Brightness.light,
  ink: AppPalette.paperInk,
  mutedInk: AppPalette.onSilverMuted,
  paper: AppPalette.silver,
  card: AppPalette.silverCard,
  dialog: AppPalette.silverDialog,
  raisedPaper: AppPalette.silverRaised,
  pressedPaper: AppPalette.silverDeep,
  border: AppPalette.silverBorder,
  outlineVariant: AppPalette.silverDeep,
  // На коже линейки нет: линуют бумагу.
  line: Color(0x00000000),
  deskStart: AppPalette.silverLight,
  deskEnd: AppPalette.silverDeep,
  navigation: AppPalette.silver,
  nested: AppPalette.silverLight,
  weekday: AppPalette.silverRaised,
  borderStart: AppPalette.silverBorder,
  borderEnd: AppPalette.silverBorderDeep,
  containerLowest: AppPalette.silverPale,
  containerLow: AppPalette.silverRaised,
  containerHigh: AppPalette.silverLight,
  containerHighest: AppPalette.silver,
  disabledButton: AppPalette.silverDeep,
  disabled: AppPalette.onSilverDisabled,
  inputFill: AppPalette.silverInput,
  switchTrackOff: AppPalette.silverDeep,
  switchThumb: AppPalette.paper,
  blue: AppPalette.indigo,
  green: AppPalette.success,
  teal: AppPalette.turquoise,
  yellow: AppPalette.amber,
  paperAsset: NotebookAssets.lightPage,
  leatherAsset: NotebookAssets.lightLeather,
);

const _darkColors = _NotebookColors(
  brightness: Brightness.dark,
  ink: AppPalette.onBlack,
  mutedInk: AppPalette.onBlackMuted,
  paper: AppPalette.black,
  card: AppPalette.blackCard,
  dialog: AppPalette.blackDialog,
  raisedPaper: AppPalette.blackRaised,
  pressedPaper: AppPalette.blackPressed,
  border: AppPalette.blackBorder,
  outlineVariant: AppPalette.blackBorderSoft,
  // На коже линейки нет: линуют бумагу.
  line: Color(0x00000000),
  deskStart: AppPalette.black,
  deskEnd: AppPalette.blackDeep,
  navigation: AppPalette.black,
  nested: AppPalette.blackNested,
  weekday: AppPalette.blackRaised,
  borderStart: AppPalette.blackBorder,
  borderEnd: AppPalette.blackBorderSoft,
  containerLowest: AppPalette.blackDeep,
  containerLow: AppPalette.black,
  containerHigh: AppPalette.blackRaised,
  containerHighest: AppPalette.blackPressed,
  disabledButton: AppPalette.blackDisabled,
  disabled: AppPalette.onBlackDisabled,
  inputFill: AppPalette.blackInput,
  switchTrackOff: AppPalette.blackBorder,
  switchThumb: AppPalette.onBlack,
  blue: AppPalette.cyan,
  green: AppPalette.success,
  teal: AppPalette.turquoise,
  yellow: AppPalette.amber,
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
    calendarTile: AppPalette.paperDay,
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
    primaryTop: AppPalette.magentaLight,
    primaryBottom: primaryDark,
    primaryShadow: AppPalette.magentaShadow,
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
    primaryContainer: AppPalette.magentaTint,
    onPrimaryContainer: AppPalette.magentaInk,
    secondary: c.blue,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFC5E2FF),
    onSecondaryContainer: const Color(0xFF062B55),
    tertiary: c.teal,
    onTertiary: Colors.white,
    surface: c.card,
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
            : AppPalette.magentaLight,
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

  return withPressPulse(base.copyWith(
    colorScheme: scheme,
    progressIndicatorTheme: quietProgressTheme(scheme),
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
      color: c.card,
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
      color: c.dialog,
      shadowColor: const Color(0x77000000),
      elevation: 8,
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: c.dialog,
      shadowColor: const Color(0x88000000),
      elevation: 10,
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: c.dialog,
      modalBackgroundColor: c.dialog,
      shadowColor: const Color(0x88000000),
      elevation: 12,
    ),
  ));
}
