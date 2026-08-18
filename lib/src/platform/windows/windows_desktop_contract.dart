class WindowsDesktopLabels {
  const WindowsDesktopLabels({
    required this.appTitle,
    required this.open,
    required this.lock,
    required this.exit,
  });

  final String appTitle;
  final String open;
  final String lock;
  final String exit;
}

abstract class WindowsDesktopPlatform {
  bool get isSupported;

  Future<void> initialize(List<String> arguments);

  Future<void> attach({
    required WindowsDesktopLabels labels,
    required Future<void> Function() onLock,
  });

  Future<void> updateLabels(WindowsDesktopLabels labels);

  Future<bool> isLaunchAtStartupEnabled();

  Future<void> setLaunchAtStartupEnabled(bool enabled);

  Future<void> detach();
}
