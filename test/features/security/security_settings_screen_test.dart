import 'package:ez_core/ez_core.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/security/ui/widgets/security_settings_card.dart';
import 'package:ezhednevnik_v2/src/features/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool? biometrics;
  var disabled = false;

  Future<void> pump(
    WidgetTester tester,
    SecuritySessionState session, {
    double width = 411,
  }) async {
    biometrics = null;
    disabled = false;
    await tester.binding.setSurfaceSize(Size(width, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SecuritySettingsCard(
            session: session,
            pinController: controller,
            message: null,
            onSavePin: () {},
            onDisablePin: () => disabled = true,
            onBiometricsChanged: (value) => biometrics = value,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  const noPin = SecuritySessionState();
  const withPin = SecuritySessionState(hasPin: true, isUnlocked: true);

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('экран защиты умещается на ширине $width', (tester) async {
      await pump(tester, withPin, width: width);
      expect(find.text('Сменить PIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('без PIN биометрию не включить, отключать нечего',
      (tester) async {
    await pump(tester, noPin);

    await tester.tap(find.byKey(const ValueKey('security_biometrics')));
    await tester.pump();

    expect(biometrics, isNull);
    expect(find.text('Сначала включите PIN'), findsOneWidget);
    expect(find.text('Включить PIN'), findsOneWidget);
    expect(find.text('Отключить PIN'), findsNothing);
  });

  testWidgets('с PIN плитка переключает биометрию, кнопка отключает PIN',
      (tester) async {
    await pump(tester, withPin);
    expect(tester.widget<SettingsToggle>(find.byType(SettingsToggle)).value,
        isFalse);

    await tester.tap(find.byKey(const ValueKey('security_biometrics')));
    await tester.pump();
    expect(biometrics, isTrue);

    await tester.tap(find.text('Отключить PIN'));
    await tester.pump();
    expect(disabled, isTrue);
  });
}
