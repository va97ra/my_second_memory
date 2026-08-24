import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Одно действие в панели метаданных: подпись, значение и нажатие.
class MetadataAction extends StatelessWidget {
  const MetadataAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.isPlaceholder = false,
    this.onClear,
    this.badgeIcon,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final valueColor = isPlaceholder ? const Color(0xFF7C746B) : color;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 17, color: valueColor),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: valueColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                    ),
                  ],
                ),
              ),
              if (badgeIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    badgeIcon,
                    key: const ValueKey('memory_reminder_enabled'),
                    size: 14,
                    color: const Color(0xFF168653),
                  ),
                ),
              if (onClear != null)
                Tooltip(
                  message: AppStrings.of(context).delete,
                  child: InkResponse(
                    onTap: onClear,
                    radius: 14,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close_rounded, size: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
