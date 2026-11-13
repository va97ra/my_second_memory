import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'windows_desktop.dart';

final windowsDesktopPlatformProvider = Provider<WindowsDesktopPlatform>(
  (ref) => windowsDesktopPlatform,
);

final windowsStartupControllerProvider =
    NotifierProvider<WindowsStartupController, AsyncValue<bool>>(
  WindowsStartupController.new,
);

class WindowsStartupController extends Notifier<AsyncValue<bool>> {
  late final WindowsDesktopPlatform _platform;

  @override
  AsyncValue<bool> build() {
    _platform = ref.watch(windowsDesktopPlatformProvider);
    if (!_platform.isSupported) return const AsyncData(false);
    _read();
    return const AsyncLoading();
  }

  /// Перечитывает, включён ли автозапуск: его могли поменять мимо приложения.
  Future<void> load() async {
    if (!_platform.isSupported) {
      state = const AsyncData(false);
      return;
    }
    state = const AsyncLoading();
    await _read();
  }

  Future<void> _read() async {
    final enabled = await AsyncValue.guard(_platform.isLaunchAtStartupEnabled);
    if (ref.mounted) state = enabled;
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
