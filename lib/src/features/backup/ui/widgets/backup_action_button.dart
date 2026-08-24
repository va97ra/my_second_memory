import 'package:flutter/material.dart';

/// Крупная кнопка резервной копии: снять или восстановить.
class BackupActionButton extends StatelessWidget {
  const BackupActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
