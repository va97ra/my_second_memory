import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ez_design/ez_design.dart';

final appThemeControllerProvider =
    NotifierProvider<AppThemeController, AppThemeStyle>(AppThemeController.new);

/// Тема экрана.
///
/// Если настройки уже прочитаны ([preferences]), тема известна сразу и первый
/// кадр рисуется ею. Без них до чтения действует [defaultStyle].
class AppThemeController extends Notifier<AppThemeStyle> {
  AppThemeController({SharedPreferences? preferences})
      : _preferences = preferences;

  static const defaultStyle = AppThemeStyle.notebookLight;
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
          ? AppThemeStyle.notebookLight
          : AppThemeStyle.notebookDark;
    }
    return defaultStyle;
  }

  @override
  AppThemeStyle build() {
    final preferences = _preferences;
    if (preferences != null) return readInitialStyle(preferences);
    _load();
    return defaultStyle;
  }

  Future<void> _load() async {
    final preferences = _preferences = await SharedPreferences.getInstance();
    if (ref.mounted) state = readInitialStyle(preferences);
  }

  Future<void> setStyle(AppThemeStyle style) async {
    state = style;
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(storageKey, style.name);
  }
}
