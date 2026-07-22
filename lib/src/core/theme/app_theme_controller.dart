import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_style.dart';

final appThemeControllerProvider =
    StateNotifierProvider<AppThemeController, AppThemeStyle>(
  (ref) => AppThemeController(),
);

class AppThemeController extends StateNotifier<AppThemeStyle> {
  AppThemeController({
    AppThemeStyle initialStyle = defaultStyle,
    SharedPreferences? preferences,
    bool loadOnStart = true,
  })  : _preferences = preferences,
        super(initialStyle) {
    if (loadOnStart) {
      _load();
    }
  }

  static const defaultStyle = AppThemeStyle.notebook;
  static const storageKey = 'app_theme_style_v2';
  static const legacyLightKey = 'app_light_theme_v1';

  SharedPreferences? _preferences;

  static AppThemeStyle readInitialStyle(SharedPreferences preferences) {
    final stored = AppThemeStyle.fromStorage(preferences.getString(storageKey));
    if (stored != null) {
      return stored;
    }
    if (preferences.containsKey(legacyLightKey)) {
      return preferences.getBool(legacyLightKey) == true
          ? AppThemeStyle.light
          : AppThemeStyle.dark;
    }
    return defaultStyle;
  }

  Future<void> _load() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    state = readInitialStyle(preferences);
  }

  Future<void> setStyle(AppThemeStyle style) async {
    state = style;
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(storageKey, style.name);
  }
}
