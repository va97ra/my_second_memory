import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../platform/windows/windows_startup_controller.dart';
import 'settings_tile.dart';
import 'settings_toggle.dart';

/// Запуск вместе с Windows.
///
/// Настройка живёт в реестре, поэтому она читается и пишется с задержкой и
/// может не записаться вовсе: у плитки есть и ожидание, и отказ.
class WindowsStartupTile extends ConsumerWidget {
  const WindowsStartupTile({super.key, required this.state});

  final AsyncValue<bool> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final enabled = state.value;

    return SettingsTile(
      key: const ValueKey('settings_windows_startup'),
      icon: Icons.desktop_windows_rounded,
      color: AppPalette.indigo,
      title: strings.launchWithWindows,
      subtitle: strings.launchWithWindowsSubtitle,
      lit: enabled ?? false,
      toggled: enabled,
      trailing: state.when(
        data: (value) => SettingsToggle(value: value),
        loading: () => const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => const Icon(Icons.refresh_rounded, size: 20),
      ),
      onTap: state.when(
        data: (value) => () => _setEnabled(context, ref, !value),
        loading: () => null,
        error: (_, __) =>
            () => ref.read(windowsStartupControllerProvider.notifier).load(),
      ),
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final saved = await ref
        .read(windowsStartupControllerProvider.notifier)
        .setEnabled(value);
    if (saved || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).launchWithWindowsFailed)),
    );
  }
}
