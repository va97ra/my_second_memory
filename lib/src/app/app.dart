import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_core/ez_core.dart';
import '../navigation/app_router.dart';
import 'package:ez_design/ez_design.dart';
import '../features/security/ui/security_gate.dart';
import '../features/security/state/security_provider.dart';
import '../features/sync/state/sync_controller.dart';
import '../platform/windows/windows_desktop.dart';
import '../platform/windows/windows_tray_frame.dart';
import 'theme/app_content_font_controller.dart';
import 'theme/app_theme_controller.dart';
import 'locale/app_locale_controller.dart';
import '../features/notifications/state/notification_providers.dart';

class EzhednevnikV2App extends ConsumerStatefulWidget {
  const EzhednevnikV2App({super.key});

  @override
  ConsumerState<EzhednevnikV2App> createState() => _EzhednevnikV2AppState();
}

class _EzhednevnikV2AppState extends ConsumerState<EzhednevnikV2App> {
  final GlobalKey<PageTurnFrameState> _rootPageTurnKey = GlobalKey();
  StreamSubscription<String>? _notificationSubscription;
  Locale? _desktopLocale;
  late final AppLifecycleListener _lifecycleObserver;
  late final ProviderSubscription<bool> _securityUnlockSubscription;

  @override
  void initState() {
    super.initState();
    _securityUnlockSubscription = ref.listenManual(
      securitySessionProvider.select((session) => session.isUnlocked),
      (_, isUnlocked) {
        ref
            .read(syncControllerProvider.notifier)
            .localDataAvailabilityChanged(isUnlocked);
      },
      fireImmediately: true,
    );
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
        unawaited(_openNotificationItem(itemId));
      }
    });
    try {
      await notifications.initialize();
    } catch (_) {
      // The app remains usable when notifications are unavailable.
    }
  }

  Future<void> _openNotificationItem(String itemId) async {
    final router = ref.read(appRouterProvider);
    final location = '/memory/view/${Uri.encodeComponent(itemId)}';
    final frame = _rootPageTurnKey.currentState;
    if (frame == null) {
      router.go(location);
      return;
    }
    final started = await frame.beginTurn(
      direction: PageTurnDirection.forward,
      switchContent: () => router.go(location),
    );
    if (!started) router.go(location);
  }

  @override
  void dispose() {
    _securityUnlockSubscription.close();
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
      AppThemeStyle.notebookLight =>
        buildNotebookTheme(brightness: Brightness.light),
      AppThemeStyle.notebookDark =>
        buildNotebookTheme(brightness: Brightness.dark),
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
      themeMode: themeStyle.isDark ? ThemeMode.dark : ThemeMode.light,
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
          child: PageTurnFrame(
            key: _rootPageTurnKey,
            provideNavigation: true,
            child: AppBackground(
              child: WindowsTrayFrame(
                child: SecurityGate(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
