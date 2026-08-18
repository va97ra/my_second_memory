import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_locale_controller.dart';
import 'core/localization/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_content_font.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/theme/app_theme_style.dart';
import 'core/theme/app_surface_palette.dart';
import 'core/theme/notebook/notebook_background.dart';
import 'core/theme/notebook/notebook_theme.dart';
import 'features/security/ui/security_gate.dart';
import 'features/security/state/security_provider.dart';
import 'features/sync/state/sync_controller.dart';
import 'features/notifications/data/notification_service.dart';
import 'platform/windows/windows_desktop.dart';
import 'platform/windows/windows_tray_frame.dart';

class EzhednevnikV2App extends ConsumerStatefulWidget {
  const EzhednevnikV2App({super.key});

  @override
  ConsumerState<EzhednevnikV2App> createState() => _EzhednevnikV2AppState();
}

class _EzhednevnikV2AppState extends ConsumerState<EzhednevnikV2App> {
  StreamSubscription<String>? _notificationSubscription;
  Locale? _desktopLocale;
  late final AppLifecycleListener _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleListener(
      onResume: () {
        ref.read(syncControllerProvider.notifier).schedule(Duration.zero);
      },
    );
    Future<void>.microtask(_initializeNotifications);
    Future<void>.microtask(() async {
      try {
        await ref.read(syncControllerProvider.notifier).load();
      } catch (_) {
        // Cloud synchronization is optional and must not block local startup.
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_attachWindowsDesktop());
    });
  }

  Future<void> _attachWindowsDesktop() async {
    if (!windowsDesktopPlatform.isSupported) return;
    final locale = ref.read(appLocaleControllerProvider);
    _desktopLocale = locale;
    try {
      await windowsDesktopPlatform.attach(
        labels: _desktopLabels(locale),
        onLock: () async {
          ref.read(securitySessionProvider.notifier).lock();
        },
      );
    } catch (_) {
      // The notebook remains usable as a regular window when tray setup fails.
    }
  }

  WindowsDesktopLabels _desktopLabels(Locale locale) {
    final strings = AppStrings(locale);
    return WindowsDesktopLabels(
      appTitle: strings.appTitle,
      open: strings.trayOpen,
      lock: strings.trayLock,
      exit: strings.trayExit,
    );
  }

  Future<void> _updateWindowsDesktopLabels(Locale locale) async {
    try {
      await windowsDesktopPlatform.updateLabels(_desktopLabels(locale));
    } catch (_) {
      // A tray refresh failure must not affect the Flutter interface.
    }
  }

  Future<void> _initializeNotifications() async {
    final notifications = ref.read(notificationServiceProvider);
    _notificationSubscription = notifications.openedItemIds.listen((itemId) {
      if (mounted) {
        ref.read(appRouterProvider).go(
              '/memory/view/${Uri.encodeComponent(itemId)}',
            );
      }
    });
    try {
      await notifications.initialize();
    } catch (_) {
      // The app remains usable when notifications are unavailable.
    }
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    _notificationSubscription?.cancel();
    unawaited(windowsDesktopPlatform.detach());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleControllerProvider);
    if (windowsDesktopPlatform.isSupported && _desktopLocale != locale) {
      _desktopLocale = locale;
      unawaited(_updateWindowsDesktopLabels(locale));
    }
    final themeStyle = ref.watch(appThemeControllerProvider);
    final contentFont = ref.watch(appContentFontControllerProvider);
    final baseTheme = switch (themeStyle) {
      AppThemeStyle.light => buildAppTheme(brightness: Brightness.light),
      AppThemeStyle.dark => buildAppTheme(brightness: Brightness.dark),
      AppThemeStyle.notebook => buildNotebookTheme(),
    };
    final selectedTheme = baseTheme.copyWith(
      extensions: [
        ...baseTheme.extensions.values,
        AppContentTypography(contentFont),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppStrings.of(context).appTitle,
      theme: selectedTheme,
      darkTheme: selectedTheme,
      themeMode:
          themeStyle == AppThemeStyle.dark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor:
              AppSurfacePalette.of(context).navigationSurface,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: AppBackground(
            child: WindowsTrayFrame(
              child: SecurityGate(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
