import 'package:ezhednevnik_v2/src/platform/windows/windows_desktop_contract.dart';
import 'package:ezhednevnik_v2/src/platform/windows/windows_startup_controller.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<void> initialize(List<String> arguments) async {}

  @override
  Future<void> updateLabels(WindowsDesktopLabels labels) async {}
}

void main() {
  test('startup controller reads and updates the real platform state',
      () async {
    final platform = _FakeWindowsDesktopPlatform(enabled: true);
    final controller = WindowsStartupController(platform);
    await controller.load();

    expect(controller.state.value, isTrue);
    expect(await controller.setEnabled(false), isTrue);
    expect(controller.state.value, isFalse);
    expect(platform.enabled, isFalse);
    controller.dispose();
  });

  test('startup controller rolls back after a platform failure', () async {
    final platform = _FakeWindowsDesktopPlatform(enabled: true);
    final controller = WindowsStartupController(platform);
    await controller.load();
    platform.failNextChange = true;

    expect(await controller.setEnabled(false), isFalse);
    expect(controller.state.value, isTrue);
    expect(platform.enabled, isTrue);
    controller.dispose();
  });

  test('unsupported platforms resolve to disabled state', () async {
    final controller = WindowsStartupController(
      _FakeWindowsDesktopPlatform(supported: false, enabled: true),
    );
    await controller.load();

    expect(controller.state.value, isFalse);
    controller.dispose();
  });
}
