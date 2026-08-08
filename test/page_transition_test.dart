import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezhednevnik_v2/src/shared/ui/page_turn_transition.dart';

void main() {
  testWidgets('route fade-through never paints two readable pages together',
      (tester) async {
    final incoming = AnimationController(vsync: tester);
    final covering = AnimationController(vsync: tester);
    addTearDown(incoming.dispose);
    addTearDown(covering.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            PageTurnTransition(
              animation: const AlwaysStoppedAnimation(1),
              secondaryAnimation: covering,
              child: const Text('old page'),
            ),
            PageTurnTransition(
              animation: incoming,
              secondaryAnimation: const AlwaysStoppedAnimation(0),
              child: const Text('new page'),
            ),
          ],
        ),
      ),
    );

    double opacityOf(String text) {
      return tester
          .widget<Opacity>(
            find
                .ancestor(of: find.text(text), matching: find.byType(Opacity))
                .first,
          )
          .opacity;
    }

    incoming.value = 0.2;
    covering.value = 0.2;
    await tester.pump();
    expect(opacityOf('old page'), greaterThan(0));
    expect(opacityOf('new page'), 0);

    incoming.value = 0.35;
    covering.value = 0.35;
    await tester.pump();
    expect(opacityOf('old page'), 0);
    expect(opacityOf('new page'), 0);

    incoming.value = 0.6;
    covering.value = 0.6;
    await tester.pump();
    expect(opacityOf('old page'), 0);
    expect(opacityOf('new page'), greaterThan(0));
  });
}
