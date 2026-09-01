import 'package:ezhednevnik_v2/src/features/engineering/engineering.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('electrical load fields use a compact grid with beginner help',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpWidget(const _EngineeringApp());
    await tester.pumpAndSettle();

    final voltage = _fieldWithLabel('Напряжение');
    final current = _fieldWithLabel('Ток нагрузки');
    final powerFactor = _fieldWithLabel('cos φ');
    final efficiency = _fieldWithLabel('КПД');

    // Напряжение — свойство сети, и стоит в своём блоке над нагрузкой.
    expect(
      tester.getTopLeft(current).dy,
      greaterThan(tester.getTopLeft(voltage).dy),
    );
    expect(tester.getTopLeft(current).dy, tester.getTopLeft(powerFactor).dy);
    expect(
      tester.getTopLeft(powerFactor).dx,
      greaterThan(tester.getTopLeft(current).dx),
    );
    expect(
      tester.getTopLeft(efficiency).dy,
      greaterThan(tester.getTopLeft(current).dy),
    );
    // Подсказка стоит под своим полем, а не блоком наверху экрана.
    expect(find.text('Что означают поля?'), findsNothing);
    expect(
      find.text('1 — нагрев, меньше — двигатель'),
      findsOneWidget,
    );
    expect(find.text('Доля полезной мощности'), findsOneWidget);

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(_fieldWithLabel('cos φ')).dy,
      greaterThan(tester.getTopLeft(_fieldWithLabel('Ток нагрузки')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ohm law shows the formula it used, not only the answer',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(const _EngineeringApp());
    await tester.pumpAndSettle();

    await pickMode(tester, 'Закон Ома');

    // Искомую величину не вводят: её поля на экране нет.
    expect(_fieldWithLabel('Напряжение'), findsNothing);
    expect(find.text('Формула: U = I × R'), findsOneWidget);
    expect(find.text('230 В = 5 А × 46 Ом'), findsOneWidget);
    expect(find.text('P = U × I = 1150 Вт'), findsOneWidget);

    // Слово стоит и на кнопке выбора, и на подписи поля.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Сопротивление'));
    await tester.pumpAndSettle();
    expect(find.text('Формула: R = U / I'), findsOneWidget);
    expect(_fieldWithLabel('Напряжение'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voltage drop answers with a verdict and keeps the voltage sane',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(const _EngineeringApp());
    await tester.pumpAndSettle();

    await pickMode(tester, 'Падение U');

    expect(find.text('Проходит по норме'), findsOneWidget);
    expect(_voltageText(tester), '230');

    // Сеть меняется — стандартное напряжение идёт следом, и туда, и обратно.
    await tester.tap(find.text('3 фазы'));
    await tester.pumpAndSettle();
    expect(_voltageText(tester), '400');
    await tester.tap(find.text('1 фаза'));
    await tester.pumpAndSettle();
    expect(_voltageText(tester), '230');

    // Введённое руками напряжение смена фаз не трогает.
    await tester.enterText(_fieldWithLabel('Напряжение'), '220');
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 фазы'));
    await tester.pumpAndSettle();
    expect(_voltageText(tester), '220');

    await tester.tap(find.text('1 фаза'));
    await tester.enterText(_fieldWithLabel('Напряжение'), '230');
    await tester.enterText(_fieldWithLabel('Длина в одну сторону'), '200');
    await tester.pumpAndSettle();
    expect(find.text('Не проходит по норме'), findsOneWidget);

    // Негодное поле названо по имени, а не «введите корректное число» на всё.
    await tester.enterText(_fieldWithLabel('cos φ'), '2');
    await tester.pumpAndSettle();
    expect(find.textContaining('cos φ —'), findsOneWidget);

    // Выбранная открытая прокладка переживает смену числа фаз.
    final routing = find.byType(DropdownButtonFormField<WireRouting>);
    await tester.ensureVisible(routing);
    await tester.pumpAndSettle();
    await tester.tap(routing);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открытая прокладка').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('3 фазы'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 фазы'));
    await tester.pumpAndSettle();
    // Сеть действительно переключилась — и прокладка осталась прежней.
    expect(_voltageText(tester), '400');
    expect(find.text('Открытая прокладка'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _EngineeringApp extends StatelessWidget {
  const _EngineeringApp();

  @override
  Widget build(BuildContext context) => testProviderScope(
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
      );
}

String _voltageText(WidgetTester tester) =>
    tester.widget<TextField>(_fieldWithLabel('Напряжение')).controller!.text;

/// Расчёт выбирают во всплывающем списке, а не кнопкой в ряду.
Future<void> pickMode(WidgetTester tester, String label) async {
  await tester.tap(find.byWidgetPredicate((widget) => widget is PopupMenuButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder _fieldWithLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
