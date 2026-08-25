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
