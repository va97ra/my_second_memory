import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../platform/windows/windows_startup_controller.dart';
import 'settings_tile.dart';

/// Запуск вместе с Windows.
///
/// Настройка живёт в реестре, поэтому она читается и пишется с задержкой и
/// может не записаться вовсе: у строки есть и ожидание, и отказ.
class WindowsStartupTile extends ConsumerWidget {
  const WindowsStartupTile({super.key, required this.state});

  final AsyncValue<bool> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);

    return SettingsTile(
      icon: Icons.desktop_windows_rounded,
      title: strings.launchWithWindows,
      subtitle: strings.launchWithWindowsSubtitle,
      trailing: state.when(
        data: (enabled) => Switch(
          value: enabled,
          onChanged: (value) => _setEnabled(context, ref, value),
        ),
        loading: () => const SizedBox.square(
          dimension: 48,
          child: Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => IconButton(
          tooltip: strings.retry,
          onPressed: ref.read(windowsStartupControllerProvider.notifier).load,
          icon: const Icon(Icons.refresh_rounded),
        ),
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
