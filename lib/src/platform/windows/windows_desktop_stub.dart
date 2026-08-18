import 'windows_desktop_contract.dart';

WindowsDesktopPlatform createWindowsDesktopPlatform() =>
    const _UnsupportedWindowsDesktopPlatform();

class _UnsupportedWindowsDesktopPlatform implements WindowsDesktopPlatform {
  const _UnsupportedWindowsDesktopPlatform();

  @override
  bool get isSupported => false;

  @override
  Future<void> initialize(List<String> arguments) async {}

  @override
  Future<void> attach({
    required WindowsDesktopLabels labels,
    required Future<void> Function() onLock,
  }) async {}

  @override
  Future<void> updateLabels(WindowsDesktopLabels labels) async {}

  @override
  Future<bool> isLaunchAtStartupEnabled() async => false;

  @override
  Future<void> setLaunchAtStartupEnabled(bool enabled) async {}

  @override
  Future<void> detach() async {}
}
