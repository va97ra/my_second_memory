import 'package:ezhednevnik_v2/src/platform/windows/windows_desktop_contract.dart';
import 'package:ezhednevnik_v2/src/platform/windows/windows_startup_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/provider_test_support.dart';

class _FakeWindowsDesktopPlatform implements WindowsDesktopPlatform {
  _FakeWindowsDesktopPlatform({this.enabled = false, this.supported = true});

  bool enabled;
  bool supported;
  bool failNextChange = false;

  @override
  bool get isSupported => supported;

  @override
  Future<bool> isLaunchAtStartupEnabled() async => enabled;

  @override
  Future<void> setLaunchAtStartupEnabled(bool value) async {
    if (failNextChange) {
      failNextChange = false;
      throw StateError('registry unavailable');
    }
    enabled = value;
  }

  @override
  Future<void> attach({
    required WindowsDesktopLabels labels,
    required Future<void> Function() onLock,
  }) async {}

  @override
  Future<void> detach() async {}

  @override
  Future<void> minimizeWindow() async {}

  @override
  Future<void> closeWindow() async {}

  @override
  Future<void> startWindowDrag() async {}

  @override
  Future<void> initialize(List<String> arguments) async {}

  @override
  Future<void> updateLabels(WindowsDesktopLabels labels) async {}
}

void main() {
  test('startup controller reads and updates the real platform state',
      () async {
    final platform = _FakeWindowsDesktopPlatform(enabled: true);
    final controller = testContainer(overrides: [
      windowsDesktopPlatformProvider.overrideWithValue(platform)
    ]).read(windowsStartupControllerProvider.notifier);
    await controller.load();

    expect(controller.state.value, isTrue);
    expect(await controller.setEnabled(false), isTrue);
    expect(controller.state.value, isFalse);
    expect(platform.enabled, isFalse);
  });

  test('startup controller rolls back after a platform failure', () async {
    final platform = _FakeWindowsDesktopPlatform(enabled: true);
    final controller = testContainer(overrides: [
      windowsDesktopPlatformProvider.overrideWithValue(platform)
    ]).read(windowsStartupControllerProvider.notifier);
    await controller.load();
    platform.failNextChange = true;

    expect(await controller.setEnabled(false), isFalse);
    expect(controller.state.value, isTrue);
    expect(platform.enabled, isTrue);
  });

  test('unsupported platforms resolve to disabled state', () async {
    final controller = testContainer(overrides: [
      windowsDesktopPlatformProvider.overrideWithValue(
          _FakeWindowsDesktopPlatform(supported: false, enabled: true))
    ]).read(windowsStartupControllerProvider.notifier);
    await controller.load();

    expect(controller.state.value, isFalse);
  });
}
