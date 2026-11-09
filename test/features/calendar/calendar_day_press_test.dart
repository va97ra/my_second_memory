import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/calendar_day_press_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: CalendarDayPressEffect(
              child: SizedBox.square(key: ValueKey('tile'), dimension: 80),
            ),
          ),
        ),
      );

  double scale(WidgetTester tester) =>
      tester
      .widget<Transform>(find.byKey(const ValueKey('press_pulse')))
      .transform
      .storage[0];

  testWidgets('плитка сжимается под пальцем и возвращается', (tester) async {
    await pump(tester);
    expect(scale(tester), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tile'))),
    );
    await tester.pump();
    // Сжатие начинается после короткой паузы: так видно, не листают ли.
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
    expect(scale(tester), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(tester), 1);
  });

  testWidgets('листание месяца снимает нажатие', (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tile'))),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(scale(tester), 1);
    await gesture.up();
  });
}
