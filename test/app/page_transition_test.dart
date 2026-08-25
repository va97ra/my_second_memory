
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/navigation/page_turn_transition.dart';

void main() {
  testWidgets('disposing a moving sheet completes the turn safely',
      (tester) async {
    final frameKey = GlobalKey<PageTurnFrameState>();
    await tester.pumpWidget(
      MaterialApp(
        home: PageTurnFrame(
          key: frameKey,
          child: const ColoredBox(color: Colors.brown),
        ),
      ),
    );
    await tester.pump();

    final turn = frameKey.currentState!.beginTurn(
      direction: PageTurnDirection.forward,
      switchContent: () {},
    );
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump();
    }
    await tester.pumpWidget(const SizedBox.shrink());

    expect(
      await turn.timeout(const Duration(seconds: 1)),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('backward turn unfolds the captured target page', (tester) async {
    final frameKey = GlobalKey<PageTurnFrameState>();
    late StateSetter setHostState;
    var page = 'current';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return PageTurnFrame(
              key: frameKey,
              child: ColoredBox(
                color: page == 'current' ? Colors.green : Colors.orange,
                child: Center(child: Text(page)),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final turn = frameKey.currentState!.beginTurn(
      direction: PageTurnDirection.backward,
      switchContent: () => setHostState(() => page = 'previous'),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const ValueKey('app_page_turn_overlay')), findsOneWidget);
    expect(find.text('previous'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(await turn, isTrue);
    expect(find.text('previous'), findsOneWidget);
  });

  testWidgets('ruled page-turn backside is enabled only for notebook theme',
      (tester) async {
    Future<void> verifyTheme(ThemeData theme, {required bool ruled}) async {
      final frameKey = GlobalKey<PageTurnFrameState>();
      late StateSetter setHostState;
      var page = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          themeAnimationDuration: Duration.zero,
          home: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return PageTurnFrame(
                key: frameKey,
                child: ColoredBox(
                  color: page ? Colors.blue : Colors.brown,
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      final turn = frameKey.currentState!.beginTurn(
        direction: PageTurnDirection.forward,
        switchContent: () => setHostState(() => page = true),
      );
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 80));

      expect(
          find.byKey(const ValueKey('app_page_turn_overlay')), findsOneWidget);
      expect(frameKey.currentState!.debugUsesRuledBackside, ruled);
      await tester.pumpAndSettle();
      expect(await turn, isTrue);
    }

    await verifyTheme(ThemeData(), ruled: false);
    await verifyTheme(
      buildNotebookTheme(brightness: Brightness.light),
      ruled: true,
    );
    await verifyTheme(
      buildNotebookTheme(brightness: Brightness.dark),
      ruled: true,
    );
  });

  testWidgets('disabled animations switch content immediately', (tester) async {
    final frameKey = GlobalKey<PageTurnFrameState>();
    var switched = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: PageTurnFrame(
            key: frameKey,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );

    final started = await frameKey.currentState!.beginTurn(
      direction: PageTurnDirection.forward,
      switchContent: () => switched = true,
    );
    expect(started, isTrue);
    expect(switched, isTrue);
    expect(find.byKey(const ValueKey('app_page_turn_overlay')), findsNothing);
  });

  for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
    testWidgets(
        '${platform.name} route starts immediately and finishes quickly',
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
          theme: ThemeData(platform: platform),
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
  }
}
