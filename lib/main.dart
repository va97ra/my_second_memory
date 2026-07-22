import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/theme/app_content_font.dart';
import 'src/core/theme/app_theme_controller.dart';
import 'src/core/theme/app_theme_style.dart';
import 'src/core/theme/notebook/notebook_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final initialStyle = AppThemeController.readInitialStyle(preferences);
  final initialContentFont =
      AppContentFontController.readInitialStyle(preferences);
  if (initialStyle == AppThemeStyle.notebook) {
    try {
      await NotebookAssets.preload();
    } catch (_) {
      // The notebook theme has a gradient fallback when assets cannot load.
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        appThemeControllerProvider.overrideWith(
          (ref) => AppThemeController(
            initialStyle: initialStyle,
            preferences: preferences,
            loadOnStart: false,
          ),
        ),
        appContentFontControllerProvider.overrideWith(
          (ref) => AppContentFontController(
            initialStyle: initialContentFont,
            preferences: preferences,
            loadOnStart: false,
          ),
        ),
      ],
      child: const EzhednevnikV2App(),
    ),
  );
}
