import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_locale_controller.dart';
import 'core/localization/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/theme/app_surface_palette.dart';
import 'features/security/ui/security_gate.dart';
import 'features/notifications/data/notification_service.dart';

class EzhednevnikV2App extends ConsumerStatefulWidget {
  const EzhednevnikV2App({super.key});

  @override
  ConsumerState<EzhednevnikV2App> createState() => _EzhednevnikV2AppState();
}

class _EzhednevnikV2AppState extends ConsumerState<EzhednevnikV2App> {
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_initializeNotifications);
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
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleControllerProvider);
    final themeMode = ref.watch(appThemeControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppStrings.of(context).appTitle,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: themeMode,
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppSurfacePalette.of(context).backgroundGradient,
            ),
            child: SecurityGate(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
