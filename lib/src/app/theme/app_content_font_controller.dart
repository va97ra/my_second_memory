import 'package:ez_design/ez_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appContentFontControllerProvider =
    NotifierProvider<AppContentFontController, AppContentFontStyle>(
  AppContentFontController.new,
);

/// Шрифт записей. Как и тема, он известен сразу, если настройки уже
/// прочитаны ([preferences]); иначе до чтения действует Manrope.
class AppContentFontController extends Notifier<AppContentFontStyle> {
  AppContentFontController({SharedPreferences? preferences})
      : _preferences = preferences;

  static const storageKey = 'app_content_font_v1';
  SharedPreferences? _preferences;

  static AppContentFontStyle readInitialStyle(SharedPreferences preferences) {
    return AppContentFontStyle.fromStorage(preferences.getString(storageKey));
  }

  @override
  AppContentFontStyle build() {
    final preferences = _preferences;
    if (preferences != null) return readInitialStyle(preferences);
    _load();
    return AppContentFontStyle.manrope;
  }

  Future<void> _load() async {
    final preferences = _preferences = await SharedPreferences.getInstance();
    if (ref.mounted) state = readInitialStyle(preferences);
  }

  Future<void> setStyle(AppContentFontStyle style) async {
    state = style;
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(storageKey, style.name);
  }
}
