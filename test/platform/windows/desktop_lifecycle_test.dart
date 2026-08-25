import 'package:ezhednevnik_v2/src/platform/windows/windows_desktop_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDesktopHost implements WindowsDesktopHost {
  int showTrayCalls = 0;
  int toggleTrayCalls = 0;
  int contextMenuCalls = 0;
  int hideCalls = 0;
  int exitCalls = 0;

  @override
  Future<void> showTrayWindow() async => showTrayCalls++;

  @override
  Future<void> toggleTrayWindow() async => toggleTrayCalls++;

  @override
  Future<void> showTrayContextMenu() async => contextMenuCalls++;

  @override
  Future<void> hideWindow() async => hideCalls++;

  @override
  Future<void> exitApplication() async => exitCalls++;
}

void main() {
  test('close hides while tray open and second instance restore', () async {
    final host = _FakeDesktopHost();
    final lifecycle = WindowsDesktopLifecycle(
      host: host,
      onLock: () async {},
    );

    await lifecycle.onWindowClose();
    await lifecycle.onTrayIconClick();
    await lifecycle.onTrayContextMenu();
    await lifecycle.onSecondInstance();

    expect(host.hideCalls, 1);
    expect(host.showTrayCalls, 1);
    expect(host.toggleTrayCalls, 1);
    expect(host.contextMenuCalls, 1);
    expect(host.exitCalls, 0);
  });

  test('tray lock clears session before hiding', () async {
    final events = <String>[];
    final host = _FakeDesktopHostWithEvents(events);
    final lifecycle = WindowsDesktopLifecycle(
      host: host,
      onLock: () async => events.add('lock'),
    );

    await lifecycle.onTrayLock();

    expect(events, ['lock', 'hide']);
  });

  test('tray exit locks once and bypasses later close interception', () async {
    final events = <String>[];
    final host = _FakeDesktopHostWithEvents(events);
    final lifecycle = WindowsDesktopLifecycle(
      host: host,
      onLock: () async => events.add('lock'),
    );

    await lifecycle.onTrayExit();
    await lifecycle.onTrayExit();
    await lifecycle.onWindowClose();

    expect(lifecycle.isExiting, isTrue);
    expect(events, ['lock', 'exit']);
  });
}

class _FakeDesktopHostWithEvents extends _FakeDesktopHost {
  _FakeDesktopHostWithEvents(this.events);

  final List<String> events;

  @override
  Future<void> hideWindow() async {
    await super.hideWindow();
    events.add('hide');
  }

  @override
  Future<void> exitApplication() async {
    await super.exitApplication();
    events.add('exit');
  }
}
