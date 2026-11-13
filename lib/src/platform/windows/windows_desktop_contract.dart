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

  /// Свернуть окно на панель задач.
  Future<void> minimizeWindow();

  /// Закрыть окно, как крестиком: оно уходит в трей, приложение работает.
  Future<void> closeWindow();

  /// Начать перетаскивание окна: окно без системного заголовка таскают за
  /// корпус.
  Future<void> startWindowDrag();

  Future<void> detach();
}
