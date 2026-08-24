import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'src/features/sync/state/sync_controller.dart';
import 'src/features/sync/state/sync_providers.dart';
import 'src/platform/windows/windows_desktop.dart';
import 'src/features/sync/state/sync_mutation_observer_provider.dart';
import 'src/app/theme/app_content_font_controller.dart';
import 'src/app/theme/app_theme_controller.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowsDesktopPlatform.initialize(arguments);
  final isSimpleAndroidBuild =
      defaultTargetPlatform == TargetPlatform.android && appFlavor == 'simple';
  var syncConfig = isSimpleAndroidBuild
      ? const SyncBackendConfig(url: '', publishableKey: '')
      : SyncBackendConfig.fromEnvironment(useBundledDefaults: true);
  debugPrint(
    'Synchronization startup: platform=$defaultTargetPlatform, '
    'flavor=$appFlavor, configured=${syncConfig.isConfigured}',
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
    await NotebookAssets.preloadCurrent(dark: initialStyle.isDark);
  } catch (_) {
    // The notebook falls back to flat colour when a texture cannot load.
  }
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
      NotebookAssets.preloadDeferred(currentIsDark: initialStyle.isDark)
          .catchError((_) {}),
    );
  });
}
