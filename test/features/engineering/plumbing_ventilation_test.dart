import 'package:ezhednevnik_v2/src/features/engineering/engineering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  Future<void> pumpEngineering(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(
      testProviderScope(
        child: const MaterialApp(
          locale: Locale('ru'),
          supportedLocales: [Locale('ru')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: EngineeringScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }

  Future<void> pickMode(WidgetTester tester, String label) async {
    await tester.tap(
      find.byWidgetPredicate((widget) => widget is PopupMenuButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('сантехника считает расход теплоносителя и уклон',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEngineering(tester);
    await openTab(tester, 'Сантехника');

    await pickMode(tester, 'Отопление');
    // 10 кВт при перепаде 20 °C переносит около 7,2 л/мин.
    expect(find.text('7.2 л/мин'), findsOneWidget);
    expect(find.textContaining('Расход: 0.4 м³/ч'), findsOneWidget);

    await pickMode(tester, 'Уклон');
    // Два процента на десяти метрах — двести миллиметров перепада.
    expect(find.text('200 мм'), findsOneWidget);
    expect(find.textContaining('Перепад на метр: 20 мм'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('вентиляция подбирает воздуховод из ряда и считает нагрев',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEngineering(tester);
    await openTab(tester, 'Вентиляция');

    // Расчётный диаметр 242,8 мм не купить — в монтаж идёт 250.
    expect(find.textContaining('Ближайший из ряда: 250 мм'), findsOneWidget);

    await pickMode(tester, 'Нагрев');
    // 500 м³/ч на 20 °C требуют около 3,35 кВт.
    expect(find.text('3.35 кВт'), findsOneWidget);

    await pickMode(tester, 'По людям');
    // Четыре человека по 60 м³/ч — 240 м³/ч, и норма названа документом.
    expect(find.text('240 м³/ч'), findsOneWidget);
    // Документ назван дважды: подсказкой под полем и строкой под ответом.
    expect(find.textContaining('СП 60.13330.2020'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
