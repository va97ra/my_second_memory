import 'package:flutter/material.dart';
import 'package:ez_design/ez_design.dart';

/// Строка в листе выбора времени и напоминания.
class ReminderSheetTile extends StatelessWidget {
  const ReminderSheetTile({super.key, 
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
    final tile = Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
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
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
    return NotebookPressable(onTap: onTap, child: tile);
  }
}
