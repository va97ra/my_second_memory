import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'windows_desktop.dart';

final windowsDesktopPlatformProvider = Provider<WindowsDesktopPlatform>(
  (ref) => windowsDesktopPlatform,
);

final windowsStartupControllerProvider =
    StateNotifierProvider<WindowsStartupController, AsyncValue<bool>>((ref) {
  return WindowsStartupController(ref.watch(windowsDesktopPlatformProvider));
});

class WindowsStartupController extends StateNotifier<AsyncValue<bool>> {
  WindowsStartupController(this._platform) : super(const AsyncLoading()) {
    load();
  }

  final WindowsDesktopPlatform _platform;

  Future<void> load() async {
    if (!_platform.isSupported) {
      state = const AsyncData(false);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_platform.isLaunchAtStartupEnabled);
  }

  Future<bool> setEnabled(bool enabled) async {
    final previous = state.value ?? false;
    state = const AsyncLoading();
    try {
      await _platform.setLaunchAtStartupEnabled(enabled);
      final actual = await _platform.isLaunchAtStartupEnabled();
      if (actual != enabled) {
        throw StateError('Windows startup state did not change');
      }
      state = AsyncData(actual);
      return true;
    } catch (_) {
      state = AsyncData(previous);
      return false;
    }
  }
}
