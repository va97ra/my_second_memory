import 'package:ez_design/ez_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appContentFontControllerProvider =
    StateNotifierProvider<AppContentFontController, AppContentFontStyle>(
  (ref) => AppContentFontController(),
);

class AppContentFontController extends StateNotifier<AppContentFontStyle> {
  AppContentFontController({
    AppContentFontStyle initialStyle = AppContentFontStyle.manrope,
    SharedPreferences? preferences,
    bool loadOnStart = true,
  })  : _preferences = preferences,
        super(initialStyle) {
    if (loadOnStart) _load();
  }

  static const storageKey = 'app_content_font_v1';
  SharedPreferences? _preferences;

  static AppContentFontStyle readInitialStyle(SharedPreferences preferences) {
    return AppContentFontStyle.fromStorage(preferences.getString(storageKey));
  }

  Future<void> _load() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    state = readInitialStyle(preferences);
  }

  Future<void> setStyle(AppContentFontStyle style) async {
    state = style;
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(storageKey, style.name);
  }
}
