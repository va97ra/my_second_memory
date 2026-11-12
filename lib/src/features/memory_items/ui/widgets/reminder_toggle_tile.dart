import 'package:flutter/material.dart';

import '../../../settings/settings.dart';
import 'reminder_tile_frame.dart';

/// Переключатель напоминания в листе времени.
class ReminderToggleTile extends StatelessWidget {
  const ReminderToggleTile({
    super.key,
    required this.accentColor,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final Color accentColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: ReminderTileFrame(
        icon: Icons.notifications_active_rounded,
        accentColor: accentColor,
        title: title,
        subtitle: subtitle,
        trailing: SettingsToggle(value: value),
        onTap: onChanged == null ? null : () => onChanged!(!value),
      ),
    );
  }
}
