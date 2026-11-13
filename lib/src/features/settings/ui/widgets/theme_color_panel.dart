import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'theme_color_picker.dart';
import 'theme_color_target.dart';

/// Палитра под образцами: что выбрано, полосы цвета и возврат к исходному.
class ThemeColorPanel extends StatelessWidget {
  const ThemeColorPanel({
    super.key,
    required this.target,
    required this.isRu,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onReset,
  });

  final ThemeColorTarget target;
  final bool isRu;
  final ValueChanged<Color> onChanged;
  final VoidCallback onChangeEnd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return NotebookCardSurface(
      depth: NotebookSurfaceDepth.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    target.label(isRu: isRu),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('theme_color_reset'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: target.isChanged(colors) ? onReset : null,
                  child: Text(isRu ? 'Как было' : 'Original'),
                ),
              ],
            ),
            ThemeColorPicker(
              // Своя палитра у каждого образца: ручки встают по его цвету.
              key: ValueKey('theme_color_picker_$target'),
              color: target.picked(colors),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ],
        ),
      ),
    );
  }
}
