import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/settings_section.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/settings_switch_tile.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  Future<void> open(WidgetTester tester, Size size, [double scale = 1]) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: const EzhednevnikV2App(),
      ),
    ));
    await tester.pumpAndSettle();
    await openTab(tester, 'settings');
  }

  test('на телефоне две плитки в ряду, при крупном шрифте меньше', () {
    expect(settingsTileColumns(336, 1), 2);
    expect(settingsTileColumns(387, 1), 2);
    expect(settingsTileColumns(258, 1.3), 1);
    expect(settingsTileColumns(736, 1), 5);
  });

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
          'плитки ничего не обрезают на ширине $width при шрифте $scale',
          (tester) async {
        await open(tester, Size(width, 900), scale);
        expect(find.text('Шрифт записей'), findsOneWidget);
        expect(find.text('Тёмная'), findsOneWidget);
        expect(find.text('Светлая'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('нажатие на всю плитку переключает настройку', (tester) async {
    await open(tester, const Size(411, 900));
    final toggle = find.descendant(
      of: find.ancestor(
        of: find.text('Показывать подсказки'),
        matching: find.byType(SettingsSwitchTile),
      ),
      matching: find.byType(SettingsToggle),
    );
    final before = tester.widget<SettingsToggle>(toggle).value;

    await tester.tap(find.text('Показывать подсказки'));
    await tester.pumpAndSettle();

    expect(tester.widget<SettingsToggle>(toggle).value, !before);
  });

  testWidgets('международные дни не нажимаются, пока выключены праздники',
      (tester) async {
    await open(tester, const Size(411, 900));
    await tester.tap(find.text('Показывать праздники'));
    await tester.pumpAndSettle();

    final opacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.text('Международные дни'),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, lessThan(1));
  });

  testWidgets('нажатие на плитку языка меняет язык', (tester) async {
    await open(tester, const Size(411, 900));
    expect(find.text('Язык'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings_language')));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
