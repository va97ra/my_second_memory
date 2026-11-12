import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Строка в листе времени и напоминания: цветная полоса, значок и подписи.
class ReminderTileFrame extends StatelessWidget {
  const ReminderTileFrame({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NotebookPressable(
      onTap: onTap,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              SizedBox(
                width: 5,
                height: double.infinity,
                child: ColoredBox(color: accentColor),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.labelLarge),
                    if (subtitle case final text?)
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              trailing,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
