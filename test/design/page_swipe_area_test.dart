import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> log;
  late List<double> scales;

  Future<void> pump(WidgetTester tester, {bool pinch = true}) {
    log = [];
    scales = [];
    return tester.pumpWidget(
      MaterialApp(
        home: PageSwipeArea(
          onHorizontalSwipe: (offset) => log.add('h$offset'),
          onVerticalSwipe: (offset) => log.add('v$offset'),
          onPinchUpdate: pinch ? scales.add : null,
          onPinchEnd: pinch ? (scale) => log.add('pinch') : null,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => log.add('tap'),
              child: const SizedBox.square(dimension: 300),
            ),
          ),
        ),
      ),
    );
  }

  /// Два пальца: [a] опускается первым, [b] — через кадр. [preA] — сдвиг
  /// первого пальца до того, как опустится второй.
  Future<void> twoFingers(
    WidgetTester tester, {
    required Offset a,
    required Offset b,
    Offset moveA = Offset.zero,
    Offset moveB = Offset.zero,
    Offset preA = Offset.zero,
  }) async {
    final first = await tester.startGesture(a, pointer: 1);
    if (preA != Offset.zero) await first.moveBy(preA);
    await tester.pump(const Duration(milliseconds: 16));
    final second = await tester.startGesture(b, pointer: 2);
    for (var step = 0; step < 10; step++) {
      if (moveA != Offset.zero) await first.moveBy(moveA / 10);
      if (moveB != Offset.zero) await second.moveBy(moveB / 10);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
  }

  testWidgets('одним пальцем листается как раньше', (tester) async {
    await pump(tester);
    await tester.dragFrom(const Offset(400, 300), const Offset(-160, 0));
    await tester.dragFrom(const Offset(400, 300), const Offset(0, 160));
    await tester.tapAt(const Offset(400, 300));
    expect(log, ['h1', 'v-1', 'tap']);
  });

  testWidgets('щипок с одним неподвижным пальцем — щипок, а не листание',
      (tester) async {
    await pump(tester);
    await twoFingers(
      tester,
      a: const Offset(250, 300),
      b: const Offset(550, 300),
      moveB: const Offset(-150, 0),
    );
    expect(log, ['pinch']);
    expect(scales.last, closeTo(0.5, 0.01));
  });

  testWidgets('второй палец после начала листания забирает жест щипку',
      (tester) async {
    await pump(tester);
    await twoFingers(
      tester,
      a: const Offset(250, 300),
      b: const Offset(550, 300),
      preA: const Offset(30, 0),
      moveA: const Offset(60, 0),
      moveB: const Offset(-60, 0),
    );
    expect(log, ['pinch']);
    expect(scales.last, lessThan(1));
  });

  testWidgets('разведение пальцев даёт масштаб больше единицы', (tester) async {
    await pump(tester);
    await twoFingers(
      tester,
      a: const Offset(400, 250),
      b: const Offset(400, 350),
      moveA: const Offset(0, -50),
      moveB: const Offset(0, 50),
    );
    expect(log, ['pinch']);
    expect(scales.last, closeTo(2, 0.01));
  });

  testWidgets('два пальца не нажимают то, что под ними', (tester) async {
    await pump(tester);
    await twoFingers(
      tester,
      a: const Offset(350, 300),
      b: const Offset(450, 300),
    );
    expect(log.where((entry) => entry == 'tap'), isEmpty);
  });

  testWidgets('без щипка два пальца листают, как и раньше', (tester) async {
    await pump(tester, pinch: false);
    await twoFingers(
      tester,
      a: const Offset(350, 300),
      b: const Offset(450, 300),
      moveA: const Offset(-150, 0),
      moveB: const Offset(-150, 0),
    );
    expect(log, ['h1']);
  });
}
