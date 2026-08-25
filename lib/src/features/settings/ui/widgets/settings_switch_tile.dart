import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/state/bool_setting_controller.dart';
import 'settings_tile.dart';

/// Строка настроек с переключателем, который сам себя помнит.
///
/// Строка знает только провайдер: читать значение и записывать его — дело
/// [BoolSettingController], а не экрана.
class SettingsSwitchTile extends ConsumerWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.setting,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final StateNotifierProvider<BoolSettingController, bool> setting;

  /// Выключенная строка видна, но не нажимается: так остаётся видно, что
  /// настройка есть и от чего она зависит.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: ref.watch(setting),
        onChanged: enabled ? ref.read(setting.notifier).setEnabled : null,
      ),
    );
  }
}
