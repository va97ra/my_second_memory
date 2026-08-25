import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/navigation/page_turn_transition.dart';
import 'package:ezhednevnik_v2/src/navigation/page_turn_navigation.dart';

void main() {
  test('page geometry keeps the left-bound sheet length while curling', () {
    const width = 400.0;
    const geometry = PageTurnGeometry(width: width, progress: 0.52);
    const samples = 800;
    for (final verticalT in [0.0, 0.5, 1.0]) {
      var previous = geometry.project(0, verticalT: verticalT);
      var measuredLength = 0.0;
      for (var sample = 1; sample <= samples; sample++) {
        final point = geometry.project(
          width * sample / samples,
          verticalT: verticalT,
        );
        measuredLength += math.sqrt(
          math.pow(point.x - previous.x, 2) +
              math.pow(point.depth - previous.depth, 2),
        );
        previous = point;
      }

      expect(measuredLength, closeTo(width, 0.8));
    }
  });

  test('page fold becomes gently diagonal only while the sheet is moving', () {
    const flat = PageTurnGeometry(width: 360, progress: 0);
    const moving = PageTurnGeometry(width: 360, progress: 0.5);
    const finished = PageTurnGeometry(width: 360, progress: 1);

    expect(flat.foldXAt(0), flat.foldXAt(1));
    expect(moving.foldXAt(0), isNot(moving.foldXAt(1)));
    expect(
      (moving.foldXAt(1) - moving.foldXAt(0)).abs(),
      inInclusiveRange(8, 24),
    );
    expect(finished.foldXAt(0), closeTo(finished.foldXAt(1), 0.001));
  });

  test('page geometry starts flat and finishes beyond the left binding', () {
    const width = 360.0;
    const flat = PageTurnGeometry(width: width, progress: 0);
    const turned = PageTurnGeometry(width: width, progress: 1);

    expect(flat.foldX, width);
    expect(flat.project(0).x, 0);
    expect(flat.project(width).x, width);
    expect(turned.foldX, lessThan(0));
    expect(turned.project(0).x, lessThan(0));
    expect(turned.project(width).x, lessThan(0));
  });

  testWidgets('forward sheet stays opaque and ignores a repeated turn',
      (tester) async {
    final frameKey = GlobalKey<PageTurnFrameState>();
    late StateSetter setHostState;
    var page = 'source';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return PageTurnFrame(
              key: frameKey,
              child: ColoredBox(
                color: page == 'source' ? Colors.brown : Colors.blue,
                child: Center(child: Text(page)),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final firstTurn = frameKey.currentState!.beginTurn(
      direction: PageTurnDirection.forward,
      switchContent: () => setHostState(() => page = 'target'),
    );
    final repeatedTurn = await frameKey.currentState!.beginTurn(
      direction: PageTurnDirection.forward,
      switchContent: () => setHostState(() => page = 'unexpected'),
    );
    expect(repeatedTurn, isFalse);

    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('app_page_turn_overlay')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('app_page_turn_overlay')),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(find.text('target'), findsOneWidget);
    expect(find.text('unexpected'), findsNothing);

    await tester.pumpAndSettle();
    expect(await firstTurn, isTrue);
    expect(find.byKey(const ValueKey('app_page_turn_overlay')), findsNothing);
    expect(find.text('target'), findsOneWidget);
  });

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

  testWidgets('revealed calendar layer never paints through the moving sheet',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const targetColor = Color(0xFF0066FF);
    final sceneKey = GlobalKey();
    final frameKey = GlobalKey<PageTurnFrameState>();
    late StateSetter setHostState;
    var targetVisible = false;

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: sceneKey,
          child: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return PageTurnFrame(
                key: frameKey,
                child: ColoredBox(
                  color: targetVisible ? targetColor : Colors.red,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final turn = frameKey.currentState!.beginTurn(
      direction: PageTurnDirection.forward,
      switchContent: () => setHostState(() => targetVisible = true),
    );
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('app_page_turn_overlay')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app_page_turn_composited_layer')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 260));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(sceneKey),
    );
    late ui.Image image;
    late ByteData bytes;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: 1);
      bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });
    addTearDown(image.dispose);

    Color pixelAt(int x, int y) {
      final offset = (y * image.width + x) * 4;
      return Color.fromARGB(
        bytes.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      );
    }

    const geometry = PageTurnGeometry(width: 360, progress: 0.5);
    final projectedXs = <double>[];
    for (var sample = 0; sample <= 360; sample++) {
      final point = geometry.project(sample.toDouble());
      final perspective = 900 / (900 - point.depth);
      projectedXs.add(point.x * perspective);
    }
    final coveredStart =
        projectedXs.reduce(math.min).ceil().clamp(0, 359).toInt() + 10;
    final coveredEnd =
        projectedXs.reduce(math.max).floor().clamp(0, 359).toInt() - 10;
    final leakedTargetPixels = <int>[];
    for (var x = coveredStart; x <= coveredEnd; x++) {
      if (pixelAt(x, 320) == targetColor) leakedTargetPixels.add(x);
    }

    expect(coveredEnd, greaterThan(coveredStart));
    expect(leakedTargetPixels, isEmpty);
    expect(pixelAt(330, 320), targetColor);

    await tester.pumpAndSettle();
    expect(await turn, isTrue);
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

  testWidgets(
      'leaving editor is covered naturally by the returning previous page',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const previousColor = Color(0xFF1267D6);
    const editorColor = Color(0xFFD62828);
    final sceneKey = GlobalKey();
    final frameKey = GlobalKey<PageTurnFrameState>();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => pageTurnPage(
            context: context,
            state: state,
            child: const Scaffold(
              body: ColoredBox(
                color: previousColor,
                child: Center(child: Text('previous route')),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/editor',
          pageBuilder: (context, state) => pageTurnPage(
            context: context,
            state: state,
            interceptBack: false,
            child: Scaffold(
              body: ColoredBox(
                color: editorColor,
                child: Center(
                  child: Builder(
                    builder: (context) => FilledButton(
                      key: const ValueKey('leave_editor'),
                      onPressed: context.pageTurnPop,
                      child: const Text('leave editor'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(platform: TargetPlatform.android),
        routerConfig: router,
        builder: (context, child) => RepaintBoundary(
          key: sceneKey,
          child: PageTurnFrame(
            key: frameKey,
            provideNavigation: true,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/editor');
    await tester.pumpAndSettle();
    expect(find.text('leave editor'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('leave_editor')));
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump();
      if (find
          .byKey(const ValueKey('app_page_turn_overlay'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('app_page_turn_overlay')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 260));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(sceneKey),
    );
    late ui.Image midpointImage;
    late ByteData midpointBytes;
    await tester.runAsync(() async {
      midpointImage = await boundary.toImage(pixelRatio: 1);
      midpointBytes = (await midpointImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
    });
    addTearDown(midpointImage.dispose);

    Color pixelAt(ui.Image image, ByteData bytes, int x, int y) {
      final offset = (y * image.width + x) * 4;
      return Color.fromARGB(
        bytes.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      );
    }

    // Halfway through the physical return, the editor is still visible only
    // in the area the previous sheet has not covered yet.
    expect(pixelAt(midpointImage, midpointBytes, 330, 320), editorColor);

    await tester.pump(const Duration(milliseconds: 130));
    late ui.Image lateImage;
    late ByteData lateBytes;
    await tester.runAsync(() async {
      lateImage = await boundary.toImage(pixelRatio: 1);
      lateBytes = (await lateImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
    });
    addTearDown(lateImage.dispose);

    // Near the end, the correctly captured previous route has unfolded over
    // the editor instead of a synthetic blank sheet.
    expect(pixelAt(lateImage, lateBytes, 50, 320), previousColor);

    await tester.pumpAndSettle();
    expect(find.text('previous route'), findsOneWidget);
    expect(find.text('leave editor'), findsNothing);
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
