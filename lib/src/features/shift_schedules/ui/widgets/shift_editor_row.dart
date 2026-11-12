import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../settings/settings.dart';

/// Строка на листе редактора: цветной значок, подпись и то, чем её меняют.
class ShiftEditorRow extends StatelessWidget {
  const ShiftEditorRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.lit = true,
    this.toggled,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool lit;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      toggled: toggled,
      child: NotebookPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SettingsIconPlate(icon: icon, color: color, lit: lit),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle case final text?)
                        Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing case final widget?) ...[
                  const SizedBox(width: 8),
                  widget,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
