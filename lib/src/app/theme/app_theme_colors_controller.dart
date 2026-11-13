import 'dart:convert';

import 'package:ez_design/ez_design.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appThemeColorsControllerProvider = NotifierProvider<
    AppThemeColorsController,
    Map<AppThemeStyle, AppThemeColors>>(AppThemeColorsController.new);

/// Цвета, выбранные человеком, — у каждой темы свои.
///
/// Лежат на устройстве рядом с самой темой и, как она, не ездят ни в
/// резервную копию, ни в синхронизацию: это оформление, а не данные.
class AppThemeColorsController
    extends Notifier<Map<AppThemeStyle, AppThemeColors>> {
  AppThemeColorsController({SharedPreferences? preferences})
      : _preferences = preferences;

  static const storageKey = 'app_theme_colors_v1';

  SharedPreferences? _preferences;

  static Map<AppThemeStyle, AppThemeColors> read(SharedPreferences? source) {
    final stored = _decode(source?.getString(storageKey));
    return {
      for (final style in AppThemeStyle.available)
        style: AppThemeColors(
          brightnessOf(style),
          chosen: Map.unmodifiable(_roles(stored[style.name]?['roles'])),
          shifts: Map.unmodifiable(_shifts(stored[style.name]?['shifts'])),
        ),
    };
  }

  @override
  Map<AppThemeStyle, AppThemeColors> build() {
    final preferences = _preferences;
    if (preferences != null) return read(preferences);
    _load();
    return read(null);
  }

  Future<void> _load() async {
    final preferences = _preferences = await SharedPreferences.getInstance();
    if (ref.mounted) state = read(preferences);
  }

  /// Запоминает цвета темы [style]. Карточка темы присылает их, когда палец
  /// отпустили: пока ручку тянут, цвета живут только на её экране.
  Future<void> setColors(AppThemeStyle style, AppThemeColors colors) async {
    state = {...state, style: colors};
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(storageKey, _encode(state));
  }

  static String _encode(Map<AppThemeStyle, AppThemeColors> all) => jsonEncode({
        for (final MapEntry(key: style, value: colors) in all.entries)
          style.name: {
            'roles': {
              for (final MapEntry(:key, :value) in colors.chosen.entries)
                key.name: value.toARGB32(),
            },
            'shifts': {
              for (final MapEntry(:key, :value) in colors.shifts.entries)
                key: value.toARGB32(),
            },
          },
      });

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null) return const {};
    try {
      return switch (jsonDecode(raw)) {
        final Map<String, dynamic> map => map,
        _ => const {},
      };
    } on FormatException {
      // Испорченная запись — то же, что её отсутствие: цвета станут исходными.
      return const {};
    }
  }

  static Map<AppColorRole, Color> _roles(Object? raw) => {
        if (raw is Map<String, dynamic>)
          for (final role in AppColorRole.values)
            if (raw[role.name] case final int value) role: Color(value),
      };

  static Map<String, Color> _shifts(Object? raw) => {
        if (raw is Map<String, dynamic>)
          for (final MapEntry(:key, :value) in raw.entries)
            if (value case final int argb) key: Color(argb),
      };
}
