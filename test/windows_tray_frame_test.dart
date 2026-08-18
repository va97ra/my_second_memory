import 'package:ezhednevnik_v2/src/platform/windows/windows_tray_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('phone-like tray frame keeps a thin themed border',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const Scaffold(
          body: WindowsTrayFrame(
            enabled: true,
            child: ColoredBox(
              key: ValueKey('content'),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(const ValueKey('content'))).dy, 0);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    final decoration = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('windows_tray_border')),
    );
    final border = (decoration.decoration as BoxDecoration).border! as Border;
    expect(border.top.width, 1);
    expect(border.left.width, 1);
    expect(border.top.color, Colors.black);
    expect(tester.takeException(), isNull);
  });
}
