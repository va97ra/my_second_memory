import 'package:flutter/material.dart';

import '../themes/notebook/notebook_visuals.dart';

/// Разделитель с подписью посередине.
class AppLabeledDivider extends StatelessWidget {
  const AppLabeledDivider({
    required this.label,
    this.padding = const EdgeInsets.fromLTRB(16, 3, 16, 3),
    this.trailingIcon,
    super.key,
  });

  final String label;
  final EdgeInsetsGeometry padding;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notebook = NotebookVisuals.maybeOf(context);
    // Ink, not black: on the dark notebook a black rule and a black label are
    // invisible against the page.
    final color = notebook != null
        ? notebook.ink.withValues(alpha: 0.82)
        : theme.colorScheme.onSurface.withValues(alpha: 0.58);
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centerWidth =
                (constraints.maxWidth * 0.68).clamp(160.0, 360.0);
            return Row(
              children: [
                Expanded(
                  child: ColoredBox(
                    key: const ValueKey('labeled_divider_left_line'),
                    color: color,
                    child: const SizedBox(height: 1.5),
                  ),
                ),
                SizedBox(
                  width: centerWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (trailingIcon != null) const SizedBox(width: 20),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 4),
                          Icon(trailingIcon, size: 16, color: color),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    key: const ValueKey('labeled_divider_right_line'),
                    color: color,
                    child: const SizedBox(height: 1.5),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
