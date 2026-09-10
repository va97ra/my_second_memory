import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/app.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'src/features/sync/sync.dart';
import 'src/platform/windows/windows_desktop.dart';
import 'src/app/theme/app_content_font_controller.dart';
import 'src/app/theme/app_theme_controller.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Каталог вложений читается один раз здесь: превью записи достаёт путь
  // синхронно, в самом build.
  await MediaStorage.initialize();
  await windowsDesktopPlatform.initialize(arguments);
  var syncConfig = SyncBackendConfig.fromEnvironment(
    useBundledDefaults: true,
  );
  debugPrint(
    'Synchronization startup: platform=$defaultTargetPlatform, '
    'configured=${syncConfig.isConfigured}',
  );
  if (syncConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: syncConfig.url,
        publishableKey: syncConfig.publishableKey,
      );
    } catch (error, stackTrace) {
      debugPrint('Synchronization initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      syncConfig = const SyncBackendConfig(url: '', publishableKey: '');
    }
  }
  final preferences = await SharedPreferences.getInstance();
  final initialStyle = AppThemeController.readInitialStyle(preferences);
  final initialContentFont =
      AppContentFontController.readInitialStyle(preferences);
  // Decode only what the first frame uses. The alternate notebook is warmed
  // once the current one is already visible.
  try {
    await NotebookAssets.preloadCurrent(
      dark: brightnessOf(initialStyle) == Brightness.dark,
    );
  } catch (_) {
    // The notebook falls back to flat colour when a texture cannot load.
  }
  // Задник экранной темы декодируется до первого кадра: иначе первый кадр
  // рисуется одним переходом, а следующий — уже с картинкой, и запуск
  // выглядит морганием фона.
  await preloadScreenBackdrop(initialStyle);
  runApp(
    ProviderScope(
      overrides: [
        syncBackendConfigProvider.overrideWithValue(syncConfig),
        syncMutationObserverProvider.overrideWith(
          (ref) => ref.watch(appSyncMutationObserverProvider),
        ),
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
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      NotebookAssets.preloadDeferred(
        currentIsDark: brightnessOf(initialStyle) == Brightness.dark,
      )
          .catchError((_) {}),
    );
  });
}
