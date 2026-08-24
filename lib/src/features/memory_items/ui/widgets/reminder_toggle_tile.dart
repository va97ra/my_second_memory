import 'package:flutter/material.dart';
import 'package:ez_design/ez_design.dart';

/// Переключатель напоминания в листе времени.
class ReminderToggleTile extends StatelessWidget {
  const ReminderToggleTile({super.key, 
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
    final tile = Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
            Icon(Icons.notifications_active_rounded,
                color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
            IgnorePointer(
              child: Switch.adaptive(value: value, onChanged: (_) {}),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
    return NotebookPressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: tile,
    );
  }
}
