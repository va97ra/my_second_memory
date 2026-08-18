import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ezhednevnik_v2/src/shared/ui/page_turn_transition.dart';

void main() {
  testWidgets('Windows route starts immediately and finishes quickly',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => pageTurnPage(
            context: context,
            state: state,
            child: const Scaffold(body: Text('first page')),
          ),
        ),
        GoRoute(
          path: '/next',
          pageBuilder: (context, state) => pageTurnPage(
            context: context,
            state: state,
            child: const Scaffold(body: Text('next page')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(platform: TargetPlatform.windows),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    router.go('/next');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    final transition = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('next page'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(transition.opacity.value, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('next page'), findsOneWidget);
    expect(find.text('first page'), findsNothing);
  });

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
