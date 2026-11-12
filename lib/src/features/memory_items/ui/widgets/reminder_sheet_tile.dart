import 'package:flutter/material.dart';

import 'reminder_tile_frame.dart';

/// Строка в листе выбора времени и напоминания.
class ReminderSheetTile extends StatelessWidget {
  const ReminderSheetTile({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ReminderTileFrame(
      icon: icon,
      accentColor: accentColor,
      title: title,
      subtitle: value,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
