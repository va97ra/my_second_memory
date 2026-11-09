import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sheet = ValueKey('sheet');
  const button = ValueKey('button');

  /// Лист с кнопкой на нём: как карточка аккаунта с глазом или запись с галочкой.
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: PressPulse(
              child: SizedBox(
                key: sheet,
                width: 200,
                height: 200,
                child: ColoredBox(
                  color: Color(0xFFFFFFFF),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: PressPulse(
                      child: ColoredBox(
                        key: button,
                        color: Color(0xFF000000),
                        child: SizedBox.square(dimension: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  double scaleOf(WidgetTester tester, int index) => tester
      .widgetList<Transform>(find.byKey(const ValueKey('press_pulse')))
      .elementAt(index)
      .transform
      .storage[0];

  double sheetScale(WidgetTester tester) => scaleOf(tester, 0);
  double buttonScale(WidgetTester tester) => scaleOf(tester, 1);

  testWidgets('нажатие на кнопку сжимает кнопку, а лист под ней стоит',
      (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(button)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 50));
    expect(buttonScale(tester), lessThan(1));
    expect(sheetScale(tester), 1);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 60));
    expect(sheetScale(tester), 1);
    await tester.pumpAndSettle();
  });

  testWidgets('мимо кнопки сжимается лист', (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byKey(sheet)) + const Offset(20, 20),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 50));
    expect(sheetScale(tester), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(sheetScale(tester), 1);
  });

  testWidgets('палец, поднятый после листания, листок не сжимает',
      (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byKey(sheet)) + const Offset(20, 20),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(sheetScale(tester), 1);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(sheetScale(tester), 1);
    await tester.pumpAndSettle();
  });

  testWidgets('начало быстрого листания листок не сжимает', (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byKey(sheet)) + const Offset(20, 20),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(sheetScale(tester), 1);
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 60));
    expect(sheetScale(tester), 1);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('быстрый тап проигрывается целиком', (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byKey(sheet)) + const Offset(20, 20),
    );
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(sheetScale(tester), lessThan(1));

    await tester.pumpAndSettle();
    expect(sheetScale(tester), 1);
  });
}
