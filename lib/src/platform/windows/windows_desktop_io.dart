import 'dart:ui';
import 'dart:async';
import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

import 'windows_desktop_contract.dart';
import 'windows_desktop_lifecycle.dart';
import 'windows_tray_window_bounds.dart';

WindowsDesktopPlatform createWindowsDesktopPlatform() =>
    _WindowsDesktopPlatformIo();

class _WindowsDesktopPlatformIo
    with WindowListener, TrayListener
    implements WindowsDesktopPlatform, WindowsDesktopHost {
  static const _singleInstanceId = 'ezhednevnik_v2_single_instance';
  static const _startupAppName = 'ezhednevnik_v2';
  static const _trayIconAsset = 'windows/runner/resources/app_icon.ico';

  bool _initialized = false;
  bool _attached = false;
  WindowsDesktopLabels? _labels;
  WindowsDesktopLifecycle? _lifecycle;

  @override
  bool get isSupported => Platform.isWindows;

  @override
  Future<void> initialize(List<String> arguments) async {
    if (!isSupported || _initialized) return;

    await windowManager.ensureInitialized();
    launchAtStartup.setup(
      appName: _startupAppName,
      appPath: Platform.resolvedExecutable,
    );
    await WindowsSingleInstance.ensureSingleInstance(
      arguments,
      _singleInstanceId,
      bringWindowToFront: false,
      onSecondWindow: (_) => unawaited(
        _lifecycle?.onSecondInstance() ?? showTrayWindow(),
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> attach({
    required WindowsDesktopLabels labels,
    required Future<void> Function() onLock,
  }) async {
    if (!isSupported) return;
    if (!_initialized) await initialize(const []);

    _labels = labels;
    _lifecycle = WindowsDesktopLifecycle(host: this, onLock: onLock);
    await trayManager.setIcon(_trayIconAsset);
    await _rebuildTrayMenu();
    if (!_attached) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _attached = true;
    }
    await windowManager.setPreventClose(true);
    await windowManager.setTitleBarStyle(
      TitleBarStyle.normal,
      windowButtonVisibility: true,
    );
    await windowManager.setResizable(false);
    await windowManager.setMinimizable(true);
    await windowManager.setMaximizable(false);
    await windowManager.setClosable(true);
    await showTrayWindow();
  }

  @override
  Future<void> updateLabels(WindowsDesktopLabels labels) async {
    if (!isSupported) return;
    _labels = labels;
    if (_attached) await _rebuildTrayMenu();
  }

  Future<void> _rebuildTrayMenu() async {
    final labels = _labels;
    if (labels == null) return;
    await windowManager.setTitle(labels.appTitle);
    await trayManager.setToolTip(labels.appTitle);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'open', label: labels.open),
          MenuItem(key: 'lock', label: labels.lock),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: labels.exit),
        ],
      ),
    );
  }

  @override
  Future<void> showTrayWindow() async {
    if (!isSupported || _lifecycle?.isExiting == true) return;
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    }
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }

    final cursor = await screenRetriever.getCursorScreenPoint();
    final displays = await screenRetriever.getAllDisplays();
    if (displays.isNotEmpty) {
      final workAreas = displays.map((display) {
        final position = display.visiblePosition ?? Offset.zero;
        final size = display.visibleSize ?? display.size;
        return position & size;
      });
      final workArea = nearestWorkArea(cursor, workAreas);
      await windowManager.setBounds(
        calculateWindowsTrayWindowBounds(workArea),
        animate: true,
      );
    }

    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> toggleTrayWindow() async {
    if (!isSupported || _lifecycle?.isExiting == true) return;
    if (await windowManager.isVisible()) {
      await hideWindow();
    } else {
      await showTrayWindow();
    }
  }

  @override
  Future<void> showTrayContextMenu() {
    return trayManager.popUpContextMenu();
  }

  @override
  Future<void> hideWindow() async {
    if (!isSupported || _lifecycle?.isExiting == true) return;
    await windowManager.hide();
  }

  @override
  Future<void> exitApplication() async {
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    final lifecycle = _lifecycle;
    if (lifecycle != null) unawaited(lifecycle.onWindowClose());
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_lifecycle?.onTrayIconClick() ?? toggleTrayWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(_lifecycle?.onTrayContextMenu() ?? showTrayContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open':
        unawaited(_lifecycle?.onTrayOpen() ?? showTrayWindow());
        return;
      case 'lock':
        final lifecycle = _lifecycle;
        if (lifecycle != null) unawaited(lifecycle.onTrayLock());
        return;
      case 'exit':
        final lifecycle = _lifecycle;
        if (lifecycle != null) unawaited(lifecycle.onTrayExit());
        return;
    }
  }

  @override
  Future<bool> isLaunchAtStartupEnabled() async {
    if (!isSupported) return false;
    if (!_initialized) {
      throw StateError('Windows desktop integration is not initialized');
    }
    return launchAtStartup.isEnabled();
  }

  @override
  Future<void> setLaunchAtStartupEnabled(bool enabled) async {
    if (!isSupported) return;
    if (!_initialized) {
      throw StateError('Windows desktop integration is not initialized');
    }
    final changed = enabled
        ? await launchAtStartup.enable()
        : await launchAtStartup.disable();
    final actual = await launchAtStartup.isEnabled();
    if (!changed || actual != enabled) {
      throw StateError('Windows startup registration was not updated');
    }
  }

  @override
  Future<void> detach() async {
    if (!isSupported || !_attached) return;
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    _attached = false;
    _lifecycle = null;
  }
}
