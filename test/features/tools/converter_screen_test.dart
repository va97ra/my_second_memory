import 'package:ezhednevnik_v2/src/features/converter/converter.dart';
import 'package:ezhednevnik_v2/src/features/converter/state/converter_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  Future<ConverterController> openConverter(WidgetTester tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(
      testProviderScope(child: const MaterialApp(home: ConverterScreen())),
    );
    await tester.pumpAndSettle();
    // Выбор единиц мышью — это выпадающий список поверх экрана; здесь важен
    // ответ конвертера, а не путь до него, поэтому пару задаёт контроллер.
    return ProviderScope.containerOf(
      tester.element(find.byType(ConverterScreen)),
    ).read(converterControllerProvider.notifier);
  }

  String textOf(WidgetTester tester, ConverterSide side) => tester
      .widget<TextField>(find.byKey(ValueKey('converter_value_${side.name}')))
      .controller!
      .text;

  Future<void> typeInto(
    WidgetTester tester,
    ConverterSide side,
    String text,
  ) async {
    await tester.enterText(
      find.byKey(ValueKey('converter_value_${side.name}')),
      text,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('число стоит под своей единицей в обеих колонках',
      (tester) async {
    await openConverter(tester);

    expect(textOf(tester, ConverterSide.left), '1');
    expect(textOf(tester, ConverterSide.right), '100');
  });

  testWidgets('считать можно с любой стороны', (tester) async {
    await openConverter(tester);
    await typeInto(tester, ConverterSide.right, '250');

    expect(textOf(tester, ConverterSide.left), '2.5');
  });

  testWidgets('кнопка между колонками меняет их местами', (tester) async {
    await openConverter(tester);

    await tester.tap(find.byKey(const ValueKey('converter_swap')));
    await tester.pumpAndSettle();

    // Величина та же: сантиметр слева, метр справа, число ушло со своей
    // единицей.
    expect(textOf(tester, ConverterSide.left), '100');
    expect(textOf(tester, ConverterSide.right), '1');
  });

  testWidgets('метр читается дюймовой дробью', (tester) async {
    final controller = await openConverter(tester);
    controller.setUnit(ConverterSide.right, 'inch_fraction');
    await tester.pumpAndSettle();

    // Метр — это не ровно 39 3/8″, и знак «≈» об этом говорит.
    expect(textOf(tester, ConverterSide.right), '≈39 3/8″');
  });

  testWidgets('дробь с фитинга набирается прямо в поле', (tester) async {
    final controller = await openConverter(tester);
    controller.setUnit(ConverterSide.left, 'inch_fraction');
    controller.setUnit(ConverterSide.right, 'mm');
    await typeInto(tester, ConverterSide.left, '3/4');

    expect(textOf(tester, ConverterSide.right), '19.05');
  });

  testWidgets('несчитаемое число не сохраняется', (tester) async {
    await openConverter(tester);
    await typeInto(tester, ConverterSide.left, 'половина');

    expect(textOf(tester, ConverterSide.right), '');
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('converter_save')),
    );
    expect(save.onPressed, isNull);
  });
}
