import 'package:ezhednevnik_v2/src/features/settings/ui/settings_screen.dart';
import 'package:ezhednevnik_v2/src/platform/windows/windows_desktop_contract.dart';
import 'package:ezhednevnik_v2/src/platform/windows/windows_startup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SettingsWindowsPlatform implements WindowsDesktopPlatform {
  _SettingsWindowsPlatform({this.supported = true});

  final bool supported;
  bool enabled = false;
  bool failNextChange = false;

  @override
  bool get isSupported => supported;

  @override
  Future<bool> isLaunchAtStartupEnabled() async => enabled;

  @override
  Future<void> setLaunchAtStartupEnabled(bool value) async {
    if (failNextChange) {
      failNextChange = false;
      throw StateError('registry unavailable');
    }
    enabled = value;
  }

  @override
  Future<void> attach({
    required WindowsDesktopLabels labels,
    required Future<void> Function() onLock,
  }) async {}

  @override
  Future<void> detach() async {}

  @override
  Future<void> initialize(List<String> arguments) async {}

  @override
  Future<void> updateLabels(WindowsDesktopLabels labels) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('Windows startup setting fits at ${width.toInt()} px',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pumpSettings(tester, _SettingsWindowsPlatform());
      final title = find.text(
        'Запускать вместе с Windows',
        skipOffstage: false,
      );
      await tester.ensureVisible(title);
      await tester.pumpAndSettle();

      final tile = find.ancestor(
        of: title,
        matching: find.byType(ListTile, skipOffstage: false),
      );
      final startupSwitch = find.descendant(
        of: tile,
        matching: find.byType(Switch, skipOffstage: false),
      );
      expect(title, findsOneWidget);
      expect(startupSwitch, findsOneWidget);
      expect(tester.getSize(startupSwitch).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('startup switch updates and reports a registry failure',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final platform = _SettingsWindowsPlatform();
    await _pumpSettings(tester, platform);
    final title = find.text(
      'Запускать вместе с Windows',
      skipOffstage: false,
    );
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    final tile = find.ancestor(
      of: title,
      matching: find.byType(ListTile, skipOffstage: false),
    );
    final startupSwitch = find.descendant(
      of: tile,
      matching: find.byType(Switch, skipOffstage: false),
    );

    await tester.tap(startupSwitch);
    await tester.pumpAndSettle();
    expect(platform.enabled, isTrue);
    expect(tester.widget<Switch>(startupSwitch).value, isTrue);

    platform.failNextChange = true;
    await tester.tap(startupSwitch);
    await tester.pumpAndSettle();
    expect(platform.enabled, isTrue);
    expect(tester.widget<Switch>(startupSwitch).value, isTrue);
    expect(find.text('Не удалось изменить автозапуск Windows'), findsOneWidget);
  });

  testWidgets('startup setting is absent outside Windows', (tester) async {
    await _pumpSettings(
      tester,
      _SettingsWindowsPlatform(supported: false),
    );

    expect(find.text('Запускать вместе с Windows'), findsNothing);
  });
}

Future<void> _pumpSettings(
  WidgetTester tester,
  WindowsDesktopPlatform platform,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        windowsDesktopPlatformProvider.overrideWithValue(platform),
      ],
      child: const MaterialApp(
        locale: Locale('ru'),
        supportedLocales: [Locale('ru'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: SettingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
