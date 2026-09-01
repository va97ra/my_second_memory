import 'package:ezhednevnik_v2/src/features/engineering/engineering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('wire sizing explains and compares conductor materials',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
      testProviderScope(child: _screen()),
    );
    await tester.pumpAndSettle();

    await _pickMode(tester, 'Подбор сечения');

    expect(_fieldWithLabel('Ток нагрузки'), findsOneWidget);
    expect(find.text('4 мм²'), findsOneWidget);
    expect(find.textContaining('Допустимый ток: 38 А'), findsOneWidget);
    expect(find.textContaining('Автомат: 32 А'), findsOneWidget);

    await tester.tap(find.text('Медь'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Алюминий').last);
    await tester.pumpAndSettle();

    expect(find.text('6 мм²'), findsOneWidget);
    expect(find.textContaining('Допустимый ток: 36 А'), findsOneWidget);

    // Нагрузку можно задать мощностью: 7 кВт при 230 В и cos φ 0,95 дают
    // те же 32 А, и для алюминия ответ остаётся прежним.
    await tester.tap(find.text('По мощности'));
    await tester.pumpAndSettle();
    expect(_fieldWithLabel('Мощность нагрузки'), findsOneWidget);
    expect(_fieldWithLabel('Ток нагрузки'), findsNothing);
    expect(find.text('6 мм²'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wire sizing remains usable at project widths and text scales',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final width in [320.0, 360.0, 600.0, 840.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        await tester.binding.setSurfaceSize(Size(width, 900));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpWidget(testProviderScope(child: _screen()));
        await tester.pumpAndSettle();
        await _pickMode(tester, 'Подбор сечения');

        expect(
          tester.takeException(),
          isNull,
          reason: '$width px at ${scale}x text',
        );
      }
    }
  });
}

Future<void> _pickMode(WidgetTester tester, String label) async {
  await tester.tap(find.byWidgetPredicate((widget) => widget is PopupMenuButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder _fieldWithLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

Widget _screen() => const MaterialApp(
      locale: Locale('ru'),
      supportedLocales: [Locale('ru')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: EngineeringScreen()),
    );
