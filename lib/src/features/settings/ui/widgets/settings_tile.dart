import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Строка настроек: значок, название и то, чем её меняют.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return NotebookPressable(
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        // Чернила по бумаге, без плашки: в этом приложении квадрат с рамкой —
        // это кнопка, а цвет называет вид записи. Строка настроек не то и не
        // другое.
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: colors.onSurfaceVariant),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing,
      ),
    );
  }
}
