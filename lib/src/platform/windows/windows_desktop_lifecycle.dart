abstract class WindowsDesktopHost {
  Future<void> showTrayWindow();

  Future<void> toggleTrayWindow();

  Future<void> showTrayContextMenu();

  Future<void> hideWindow();

  Future<void> exitApplication();
}

class WindowsDesktopLifecycle {
  WindowsDesktopLifecycle({
    required WindowsDesktopHost host,
    required Future<void> Function() onLock,
  })  : _host = host,
        _onLock = onLock;

  final WindowsDesktopHost _host;
  final Future<void> Function() _onLock;
  bool _isExiting = false;

  bool get isExiting => _isExiting;

  Future<void> onWindowClose() async {
    if (!_isExiting) await _host.hideWindow();
  }

  Future<void> onTrayIconClick() => _host.toggleTrayWindow();

  Future<void> onTrayOpen() => _host.showTrayWindow();

  Future<void> onTrayContextMenu() => _host.showTrayContextMenu();

  Future<void> onSecondInstance() => _host.showTrayWindow();

  Future<void> onTrayLock() async {
    if (_isExiting) return;
    await _onLock();
    await _host.hideWindow();
  }

  Future<void> onTrayExit() async {
    if (_isExiting) return;
    _isExiting = true;
    await _onLock();
    await _host.exitApplication();
  }
}
