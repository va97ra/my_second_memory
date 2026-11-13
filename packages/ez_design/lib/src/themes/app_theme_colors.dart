import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';

/// Что в теме человек может перекрасить сам.
///
/// Виды записей названы так же, как `MemoryType`: оформление о записях не
/// знает, и приложение сопоставляет вид с его цветом само.
enum AppColorRole {
  accent,
  weekend,
  shortenedDay,
  today,
  task,
  note,
  voiceNote,
  event,
  person,
  habit,
  goal,
  project,
  purchase,
  document,
  place,
  birthday,
  payment,
}

/// Цвета темы, которые может выбрать человек, — у каждой темы свои.
///
/// Хранится только то, что выбрано вместо исходного. Выбранный цвет бывает
/// полупрозрачным; экрану он отдаётся уже положенным на свою подложку, поэтому
/// прозрачность делает его бледнее, а не просвечивает кожей.
///
/// Тема записана здесь своя, а не та, что у [ThemeData]: внутри листа бумаги
/// схема всегда светлая, а цвета остаются цветами страницы, на которой он лежит.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors(
    this.brightness, {
    this.chosen = const {},
    this.shifts = const {},
  });

  final Brightness brightness;

  /// Выбранное человеком вместо исходного, как есть — с прозрачностью.
  final Map<AppColorRole, Color> chosen;

  /// Цвета графиков смен в этой теме по id графика. Исходный цвет графика
  /// лежит в нём самом; здесь только то, чем тема его заменила.
  final Map<String, Color> shifts;

  static AppThemeColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppThemeColors>() ??
        AppThemeColors(theme.brightness);
  }

  bool get _dark => brightness == Brightness.dark;

  /// Исходный цвет: решения владельца от 4 ноября 2026.
  Color original(AppColorRole role) => switch (role) {
        AppColorRole.accent || AppColorRole.weekend => AppPalette.magenta,
        AppColorRole.shortenedDay => AppPalette.amber,
        // На серебре голубой теряется.
        AppColorRole.today => _dark ? AppPalette.cyan : AppPalette.indigo,
        AppColorRole.task => AppPalette.cyan,
        AppColorRole.note => AppPalette.amber,
        AppColorRole.voiceNote || AppColorRole.purchase => AppPalette.magenta,
        AppColorRole.event => AppPalette.violet,
        AppColorRole.person ||
        AppColorRole.habit ||
        AppColorRole.payment =>
          AppPalette.turquoise,
        AppColorRole.goal => AppPalette.orange,
        AppColorRole.project => AppPalette.indigo,
        // Крафтовая папка. Серым вид записи быть не может: серый значит
        // «выполнено».
        AppColorRole.document => AppPalette.amberDeep,
        AppColorRole.place => AppPalette.danger,
        AppColorRole.birthday => AppPalette.magentaLight,
      };

  /// На чём цвет лежит: с этим и смешивается его прозрачность.
  Color ground(AppColorRole role) => switch (role) {
        AppColorRole.accent =>
          _dark ? AppPalette.blackCard : AppPalette.silverCard,
        AppColorRole.weekend ||
        AppColorRole.shortenedDay ||
        AppColorRole.today =>
          AppPalette.paperDay,
        _ => AppPalette.paper,
      };

  /// Выбранный цвет как есть, с прозрачностью.
  Color picked(AppColorRole role) => chosen[role] ?? original(role);

  bool isChanged(AppColorRole role) => chosen.containsKey(role);

  /// Готовый цвет для экрана: выбранный, положенный на свою подложку.
  Color operator [](AppColorRole role) =>
      Color.alphaBlend(picked(role), ground(role));

  /// Цвет графика [id] как есть; [original] — тот, что записан в графике.
  Color pickedShift(String id, Color original) => shifts[id] ?? original;

  /// Готовый цвет графика: дни смены лежат на бумаге дня, как и выходные.
  Color shift(String id, Color original) =>
      Color.alphaBlend(pickedShift(id, original), AppPalette.paperDay);

  /// Тот же набор с другим цветом [role]; `null` возвращает исходный.
  AppThemeColors withColor(AppColorRole role, Color? color) {
    final next = {...chosen}..remove(role);
    if (color != null && color != original(role)) next[role] = color;
    return AppThemeColors(
      brightness,
      chosen: Map.unmodifiable(next),
      shifts: shifts,
    );
  }

  /// Тот же набор с другим цветом графика [id]; `null` возвращает исходный.
  AppThemeColors withShiftColor(String id, Color? color) {
    final next = {...shifts}..remove(id);
    if (color != null) next[id] = color;
    return AppThemeColors(
      brightness,
      chosen: chosen,
      shifts: Map.unmodifiable(next),
    );
  }

  @override
  AppThemeColors copyWith() => this;

  /// Цвета не перетекают: выбор применяется сразу, как и смена темы.
  @override
  AppThemeColors lerp(AppThemeColors? other, double t) =>
      other == null || t < 0.5 ? this : other;

  @override
  bool operator ==(Object other) =>
      other is AppThemeColors &&
      other.brightness == brightness &&
      mapEquals(other.chosen, chosen) &&
      mapEquals(other.shifts, shifts);

  @override
  int get hashCode => Object.hash(
        brightness,
        Object.hashAllUnordered(
          chosen.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
        Object.hashAllUnordered(
          shifts.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
      );
}
