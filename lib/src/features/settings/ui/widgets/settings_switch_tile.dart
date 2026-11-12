import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/state/bool_setting_controller.dart';
import 'settings_tile.dart';
import 'settings_toggle.dart';

/// Плитка с переключателем, который сам себя помнит.
///
/// Плитка знает только провайдер: читать значение и записывать его — дело
/// [BoolSettingController], а не экрана.
class SettingsSwitchTile extends ConsumerWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.setting,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final StateNotifierProvider<BoolSettingController, bool> setting;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(setting);
    return SettingsTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      lit: value,
      toggled: value,
      enabled: enabled,
      trailing: SettingsToggle(value: value),
      onTap: () => ref.read(setting.notifier).setEnabled(!value),
    );
  }
}
