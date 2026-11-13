import 'package:ezhednevnik_v2/src/platform/windows/windows_desktop.dart';
import 'package:ezhednevnik_v2/src/platform/windows/windows_phone_frame.dart';
import 'package:ezhednevnik_v2/src/platform/windows/windows_tray_window_bounds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _WindowControls implements WindowsDesktopPlatform {
  int minimized = 0;
  int closed = 0;
  int dragged = 0;

  @override
  bool get isSupported => true;

  @override
  Future<void> minimizeWindow() async => minimized++;

  @override
  Future<void> closeWindow() async => closed++;

  @override
  Future<void> startWindowDrag() async => dragged++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<Size> _pumpFrame(
  WidgetTester tester, {
  required bool enabled,
  _WindowControls? window,
}) async {
  tester.view.physicalSize =
      const Size(windowsTrayWindowWidth, windowsTrayWindowHeight);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late Size seen;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      builder: (context, child) => WindowsPhoneFrame(
        enabled: enabled,
        platform: window,
        child: child!,
      ),
      home: Builder(builder: (context) {
        seen = MediaQuery.sizeOf(context);
        return const ColoredBox(
          key: ValueKey('content'),
          color: Colors.white,
        );
      }),
    ),
  );
  return seen;
}

void main() {
  testWidgets('the app sees the phone screen inside the body', (tester) async {
    final seen = await _pumpFrame(tester, enabled: true);

    const screen = Size(windowsPhoneScreenWidth, windowsPhoneScreenHeight);
    expect(seen, screen);
    expect(
      tester.getRect(find.byKey(const ValueKey('content'))),
      const Offset(windowsPhoneBezelSide, windowsPhoneBezelTop) & screen,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('window buttons sit together on the straight top bezel',
      (tester) async {
    await _pumpFrame(tester, enabled: true);

    final minimize =
        tester.getRect(find.byKey(const ValueKey('windows_phone_minimize')));
    final close =
        tester.getRect(find.byKey(const ValueKey('windows_phone_close')));
    final bodyRight = windowsTrayWindowWidth - windowsPhoneSideButtonsOutset;

    // Как в Windows: справа, «свернуть» перед «закрыть», на одной линии.
    expect(minimize.right, lessThan(close.left));
    expect(close.left - minimize.right, lessThan(12));
    expect(minimize.center.dy, close.center.dy);
    expect(minimize.left, greaterThan(windowsTrayWindowWidth / 2));
    // Не на дуге скругления угла, а на прямом участке рамки.
    expect(close.right, lessThanOrEqualTo(bodyRight - 46));
    // Внутри верхней рамки, над экраном.
    expect(close.bottom, lessThanOrEqualTo(windowsPhoneBezelTop));
    expect(close.center.dy, windowsPhoneBezelTop / 2);
  });

  testWidgets('the body buttons minimize, close and drag the window',
      (tester) async {
    final window = _WindowControls();
    await _pumpFrame(tester, enabled: true, window: window);

    await tester.tap(find.byKey(const ValueKey('windows_phone_minimize')));
    await tester.tap(find.byKey(const ValueKey('windows_phone_close')));
    await tester.pumpAndSettle();
    expect(window.minimized, 1);
    expect(window.closed, 1);

    // Тащат за нижнюю рамку: на ней нет ни экрана, ни кнопок.
    await tester.dragFrom(
      const Offset(
        windowsTrayWindowWidth / 2,
        windowsTrayWindowHeight - windowsPhoneBezelBottom / 2,
      ),
      const Offset(0, -40),
    );
    expect(window.dragged, 1);
  });

  testWidgets('off Windows the app fills the window as it is', (tester) async {
    final seen = await _pumpFrame(tester, enabled: false);

    expect(seen, const Size(windowsTrayWindowWidth, windowsTrayWindowHeight));
    expect(find.byKey(const ValueKey('windows_phone_body')), findsNothing);
  });
}
