import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appThemeControllerProvider =
    StateNotifierProvider<AppThemeController, ThemeMode>(
  (ref) => AppThemeController(),
);

class AppThemeController extends StateNotifier<ThemeMode> {
  AppThemeController() : super(ThemeMode.dark) {
    _load();
  }

  static const _key = 'app_light_theme_v1';

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    state =
        preferences.getBool(_key) == true ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setLight(bool enabled) async {
    state = enabled ? ThemeMode.light : ThemeMode.dark;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, enabled);
  }
}
